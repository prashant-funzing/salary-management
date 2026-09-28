require "test_helper"

class ReportsApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_hr
    @employee = create_employee
    create_salary(@employee, @user, annual_ctc: "100", components: { "Basic" => "100" })
    create_salary(@employee, @user, effective_on: "2027-01-01", annual_ctc: "200", components: { "Basic" => "200" })
    create_employee("UNPAID")
    inactive = create_employee("INACTIVE", status: "inactive")
    create_salary(inactive, @user)
    sign_in(@user)
  end

  test "headcount includes unpaid employees but excludes inactive employees" do
    get "/api/reports", params: { as_of: "2026-06-01" }
    assert_equal 2, response.parsed_body["headcount"]
    assert_equal 1, response.parsed_body["compensated_headcount"]
    assert_equal "100.0", response.parsed_body["totals"].first["annual_ctc"]
  end

  test "report dates select exactly one salary per employee at the boundary" do
    { "2025-12-31" => nil, "2026-01-01" => "100.0", "2026-12-31" => "100.0", "2027-01-01" => "200.0" }.each do |date, amount|
      get "/api/reports", params: { as_of: date }
      assert_response :success
      actual = response.parsed_body["totals"].first&.fetch("annual_ctc")
      amount.nil? ? assert_nil(actual, date) : assert_equal(amount, actual, date)
    end
  end

  test "grouping allowlist and filters apply without interpolating arbitrary columns" do
    { "department" => "Engineering", "country" => "India", "level" => "L3", "DROP TABLE employees" => "Engineering" }.each do |dimension, name|
      get "/api/reports", params: { as_of: "2026-06-01", group_by: dimension }
      assert_response :success
      assert_equal [ name ], response.parsed_body["groups"].map { |row| row["name"] }
    end
    get "/api/reports", params: { country: "Canada" }
    assert_equal 0, response.parsed_body["headcount"]
    assert_empty response.parsed_body["groups"]
  end

  test "invalid dates return a client error" do
    get "/api/reports", params: { as_of: "not-a-date" }
    assert_response :bad_request
    get "/api/reports", params: { as_of: "2026-02-30" }
    assert_response :bad_request
  end

  test "odd median is exact and independent of employee insertion order" do
    [ "300.03", "200.02" ].each_with_index do |amount, i|
      create_salary(create_employee("MEDIAN#{i}"), @user, annual_ctc: amount, components: { "Basic" => amount })
    end
    get "/api/reports", params: { as_of: "2026-06-01" }
    assert_equal "200.02", response.parsed_body["totals"].first["median"]
  end
end
