require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "email is normalized before uniqueness validation" do
    employee = create_employee(email: " ASHA@EXAMPLE.COM ")
    assert_equal "asha@example.com", employee.email
    duplicate = Employee.new(employee_attributes("E2", email: "ASHA@example.com"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "required attributes and length constraints are enforced" do
    %i[employee_code name email country department level].each do |field|
      assert_not Employee.new(employee_attributes.merge(field => "")).valid?, field
      assert_not Employee.new(employee_attributes.merge(field => "x" * 121)).valid?, field
    end
  end

  test "employees with salary history cannot be deleted" do
    employee = create_employee
    create_salary(employee, create_hr)
    assert_raises(ActiveRecord::DeleteRestrictionError) { employee.destroy! }
    assert Employee.exists?(employee.id)
    assert_equal 1, employee.compensations.count
  end
end
