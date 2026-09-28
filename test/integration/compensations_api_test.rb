require "test_helper"

class CompensationsApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_hr
    @employee = create_employee
    @path = "/api/employees/#{@employee.id}/compensations"
    sign_in(@user)
  end

  test "recording a salary sets actor and increments employee version" do
    outsider = User.create!(email: "other@example.com", password: "OtherPassword123!")
    post @path, params: { lock_version: 0, compensation: salary_attributes(user_id: outsider.id, employee_id: 999) }, as: :json
    assert_response :created
    assert_equal @user.id, Compensation.last.user_id
    assert_equal @employee.id, Compensation.last.employee_id
    assert_equal 1, @employee.reload.lock_version
    assert_equal "Annual review", response.parsed_body["reason"]
  end

  test "invalid salary and duplicate dates leave the employee version unchanged" do
    post @path, params: { lock_version: 0, compensation: salary_attributes(annual_ctc: "1") }, as: :json
    assert_response :unprocessable_entity
    assert_equal 0, @employee.reload.lock_version
    assert_equal 0, Compensation.count
    post @path, params: { lock_version: 0, compensation: salary_attributes }, as: :json
    assert_response :created
    post @path, params: { lock_version: 1, compensation: salary_attributes }, as: :json
    assert_response :unprocessable_entity
    assert_equal 1, Compensation.count
    assert_equal 1, @employee.reload.lock_version
  end

  test "stale missing and malformed versions do not write salary history" do
    @employee.update!(name: "Edited elsewhere")
    [ [ 0, :conflict ], [ nil, :bad_request ], [ "abc", :bad_request ] ].each do |version, status|
      assert_no_difference("Compensation.count") do
        post @path, params: { lock_version: version, compensation: salary_attributes }, as: :json
        assert_response status
      end
    end
  end

  test "unknown employee and missing compensation payload are handled" do
    post "/api/employees/999999999/compensations", params: { lock_version: 0, compensation: salary_attributes }, as: :json
    assert_response :not_found
    post @path, params: { lock_version: 0 }, as: :json
    assert_response :bad_request
  end
  test "malformed compensation payload and fractional version cannot create history" do
    post @path, params: { lock_version: 0, compensation: "text" }, as: :json
    assert_response :bad_request
    post @path, params: { lock_version: 0.5, compensation: salary_attributes }, as: :json
    assert_response :bad_request
    assert_equal 0, Compensation.count
  end
end
