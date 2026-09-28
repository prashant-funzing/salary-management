module SalaryTestData
  def create_hr
    User.create!(email: "hr@example.com", password: "TestPassword123!")
  end

  def employee_attributes(code = "E1", **overrides)
    { employee_code: code, name: "Asha Singh", email: "#{code.downcase}@example.com", country: "India", department: "Engineering", level: "L3", status: "active" }.merge(overrides)
  end

  def create_employee(code = "E1", **overrides)
    Employee.create!(employee_attributes(code, **overrides))
  end

  def salary_attributes(**overrides)
    { annual_ctc: "1200000", currency: "INR", effective_on: "2026-01-01", reason: "Annual review", components: { "Basic" => "480000", "HRA" => "240000", "Special Allowance" => "480000" } }.merge(overrides)
  end

  def create_salary(employee, user, **overrides)
    employee.compensations.create!(salary_attributes(**overrides).merge(user: user))
  end

  def sign_in(user)
    post "/api/session", params: { email: user.email, password: "TestPassword123!" }, as: :json
    assert_response :success
  end
end
