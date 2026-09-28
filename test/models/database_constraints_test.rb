require "test_helper"

class DatabaseConstraintsTest < ActiveSupport::TestCase
  setup do
    @user = create_hr
    @employee = create_employee
    @salary = create_salary(@employee, @user)
  end

  test "database rejects duplicate effective dates independently of model validation" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Compensation.transaction(requires_new: true) do
        Compensation.insert_all!([ @salary.attributes.except("id") ])
      end
    end
  end

  test "database rejects invalid status currency total and employee foreign key" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Employee.transaction(requires_new: true) { @employee.update_columns(status: "deleted") }
    end
    [ { annual_ctc: 0 }, { currency: "XYZ" }, { employee_id: 999999999 } ].each do |changes|
      assert_raises(ActiveRecord::StatementInvalid) do
        Compensation.transaction(requires_new: true) { @salary.update_columns(changes) }
      end
    end
    assert_equal BigDecimal("1200000"), @salary.reload.annual_ctc
    assert_equal "active", @employee.reload.status
  end
end
