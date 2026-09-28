require "test_helper"

class HrWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "hr@example.com", password: "TestPassword123!")
  end

  test "anonymous requests cannot access salary information" do
    get "/api/employees"
    assert_response :unauthorized
    get "/api/reports"
    assert_response :unauthorized
  end

  test "HR creates employee records salary and reads report" do
    post "/api/session", params: { email: @user.email, password: "TestPassword123!" }, as: :json
    assert_response :success
    post "/api/employees", params: { employee: { employee_code: "E1", name: "Asha Singh", email: "asha@example.com", country: "India", department: "Engineering", level: "L3" } }, as: :json
    assert_response :created
    employee = response.parsed_body
    post "/api/employees/#{employee['id']}/compensations", params: { lock_version: 0, compensation: { annual_ctc: "1200000", currency: "INR", effective_on: "2026-01-01", reason: "Initial offer", components: { Basic: "1200000" } } }, as: :json
    assert_response :created
    get "/api/reports", params: { as_of: "2026-06-01" }
    assert_response :success
    assert_equal "1200000.0", response.parsed_body["totals"][0]["annual_ctc"]
    get "/api/employees", params: { q: "Asha" }
    assert_equal 1, response.parsed_body["total"]
    assert_equal "100000.0", response.parsed_body["employees"][0]["compensation"]["monthly_ctc"]
    delete "/api/session"
    get "/api/employees"
    assert_response :unauthorized
  end
  test "mixed currencies remain separate and reference conversion is labeled" do
    post "/api/session", params: { email: @user.email, password: "TestPassword123!" }, as: :json
    %w[INR USD].each_with_index do |currency, index|
      employee = Employee.create!(employee_code: "E#{index}", name: "Test", email: "e#{index}@example.com", country: "India", department: "Engineering", level: "L1")
      employee.compensations.create!(user: @user, currency: currency, annual_ctc: "1200", components: { "Basic" => "1200" }, effective_on: "2026-01-01", reason: "Initial")
    end
    get "/api/reports", params: { as_of: "2026-06-01" }
    assert_equal %w[INR USD], response.parsed_body["totals"].map { |row| row["currency"] }.sort
    assert_equal "103200.0", response.parsed_body["planning_equivalent"]["annual_ctc"]
    assert_match "Illustrative", response.parsed_body["planning_equivalent"]["note"]
  end

  test "CSRF protection rejects mutations without a token" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post "/api/session", params: { email: @user.email, password: "TestPassword123!" }, as: :json
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
  test "reports handle empty results and exact even-sized medians" do
    post "/api/session", params: { email: @user.email, password: "TestPassword123!" }, as: :json
    get "/api/reports"
    assert_response :success
    assert_equal "0.0", response.parsed_body["planning_equivalent"]["annual_ctc"]
    %w[100.01 200.02].each_with_index do |amount, index|
      employee = Employee.create!(employee_code: "M#{index}", name: "Test", email: "m#{index}@example.com", country: "India", department: "Finance", level: "L1")
      employee.compensations.create!(user: @user, currency: "INR", annual_ctc: amount, components: { "Basic" => amount }, effective_on: "2026-01-01", reason: "Initial")
    end
    get "/api/reports", params: { as_of: "2026-06-01" }
    assert_equal BigDecimal("150.015"), BigDecimal(response.parsed_body["totals"][0]["median"])
  end
end
