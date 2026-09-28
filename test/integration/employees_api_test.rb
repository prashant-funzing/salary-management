require "test_helper"

class EmployeesApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_hr
    sign_in(@user)
  end

  test "pagination has stable order no overlap and bounded results" do
    employees = (1..26).map { |i| create_employee("P#{i}") }
    get "/api/employees", params: { page: 1 }
    first = response.parsed_body
    assert_equal 26, first["total"]
    assert_equal employees.first(25).map(&:id), first["employees"].map { |e| e["id"] }
    get "/api/employees", params: { page: 2 }
    assert_equal [ employees.last.id ], response.parsed_body["employees"].map { |e| e["id"] }
    get "/api/employees", params: { page: 3 }
    assert_empty response.parsed_body["employees"]
    get "/api/employees", params: { page: -1 }
    assert_equal 1, response.parsed_body["page"]
  end

  test "case insensitive search covers name email and employee code" do
    employee = create_employee("ABC-001", name: "Asha Percent%", email: "asha@example.com")
    create_employee("OTHER", name: "Someone Else")
    [ "ASHA PERCENT", "ASHA@EXAMPLE", "abc-001", "%" ].each do |query|
      get "/api/employees", params: { q: query }
      assert_equal [ employee.id ], response.parsed_body["employees"].map { |e| e["id"] }, query
    end
    get "/api/employees", params: { q: "_' OR 1=1 --" }
    assert_equal 0, response.parsed_body["total"]
  end

  test "all directory filters are combined and options are distinct sorted values" do
    wanted = create_employee
    create_employee("E2", department: "Finance", status: "inactive")
    create_employee("E3", country: "Canada", level: "L4")
    get "/api/employees", params: { country: "India", department: "Engineering", level: "L3", status: "active" }
    assert_equal [ wanted.id ], response.parsed_body["employees"].map { |e| e["id"] }
    get "/api/employees", params: { status: "inactive" }
    assert_equal 1, response.parsed_body["total"]
    get "/api/employees/options"
    assert_equal %w[Canada India], response.parsed_body["country"]
    assert_equal %w[Engineering Finance], response.parsed_body["department"]
    assert_equal Compensation::CURRENCIES, response.parsed_body["currencies"]
  end

  test "directory selects current salary while detail preserves ordered history and actor" do
    travel_to Time.utc(2026, 6, 1) do
      employee = create_employee
      current = create_salary(employee, @user)
      future = create_salary(employee, @user, effective_on: "2027-01-01")
      unpaid = create_employee("UNPAID")
      get "/api/employees"
      rows = response.parsed_body["employees"].index_by { |e| e["id"] }
      assert_equal current.id, rows[employee.id]["compensation"]["id"]
      assert_nil rows[unpaid.id]["compensation"]
      assert_equal "no-store", response.headers["Cache-Control"]
      get "/api/employees/#{employee.id}"
      assert_equal [ future.id, current.id ], response.parsed_body["history"].map { |s| s["id"] }
      assert_equal @user.email, response.parsed_body["history"].first["recorded_by"]
    end
  end

  test "editing requires version and stale edits cannot overwrite a newer change" do
    employee = create_employee
    patch "/api/employees/#{employee.id}", params: { employee: { name: "First edit", lock_version: 0 } }, as: :json
    assert_response :success
    assert_equal 1, response.parsed_body["lock_version"]
    patch "/api/employees/#{employee.id}", params: { employee: { name: "Stale edit", lock_version: 0 } }, as: :json
    assert_response :conflict
    assert_equal "First edit", employee.reload.name
    patch "/api/employees/#{employee.id}", params: { employee: { name: "Missing version" } }, as: :json
    assert_response :bad_request
  end

  test "invalid and duplicate employee records return validation errors" do
    create_employee
    [ employee_attributes, employee_attributes("E2", email: "invalid"), employee_attributes("E3", status: "deleted"), employee_attributes("E4", name: "") ].each do |attributes|
      assert_no_difference("Employee.count") do
        post "/api/employees", params: { employee: attributes }, as: :json
        assert_response :unprocessable_entity
        assert response.parsed_body["error"].present?
      end
    end
  end

  test "unknown employees and missing request payloads have JSON errors" do
    get "/api/employees/999999999"
    assert_response :not_found
    assert_equal "Record not found", response.parsed_body["error"]
    post "/api/employees", params: {}, as: :json
    assert_response :bad_request
  end
  test "malformed employee payloads return bad request instead of server errors" do
    employee = create_employee
    [ "text", [ { name: "Unexpected array" } ] ].each do |payload|
      post "/api/employees", params: { employee: payload }, as: :json
      assert_response :bad_request
      patch "/api/employees/#{employee.id}", params: { employee: payload }, as: :json
      assert_response :bad_request
    end
  end

  test "fractional and malformed employee versions are rejected without edits" do
    employee = create_employee
    [ 0.5, "0oops", -1 ].each do |version|
      patch "/api/employees/#{employee.id}", params: { employee: { name: "Invalid edit", lock_version: version } }, as: :json
      assert_response :bad_request
      assert_equal "Asha Singh", employee.reload.name
    end
  end
end
