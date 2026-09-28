require "test_helper"

class CompensationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "test@example.com", password: "TestPassword123!")
    @employee = Employee.create!(employee_code: "E1", name: "Test Employee", email: "employee@example.com", country: "India", department: "Engineering", level: "L3")
    @attributes = { effective_on: "2026-01-01", currency: "INR", annual_ctc: "1200000", reason: "Annual review", components: { "Basic" => "480000", "HRA" => "240000", "Special Allowance" => "480000" } }
  end

  test "12 LPA yields one lakh monthly and components reconcile" do
    salary = @employee.compensations.create!(@attributes.merge(user: @user))
    assert_equal BigDecimal("100000"), salary.monthly_ctc
    assert_equal "40000.0", salary.summary[:monthly_components]["Basic"]
    assert_equal "0.0", salary.summary[:rounding_adjustment]
  end

  test "rejects mismatched negative and malformed component amounts" do
    [ { "Basic" => "1" }, { "Basic" => "-1" }, { "Basic" => "NaN" }, { "Basic" => "Infinity" }, { "Basic" => "abc" } ].each do |components|
      salary = @employee.compensations.new(@attributes.merge(user: @user, components: components))
      assert_not salary.valid?, components.inspect
    end
  end

  test "future increment preserves currently effective salary" do
    old = @employee.compensations.create!(@attributes.merge(user: @user))
    future = @employee.compensations.create!(@attributes.merge(user: @user, effective_on: "2027-01-01"))
    assert_equal [ old.id ], Compensation.effective_on(Date.new(2026, 12, 31)).pluck(:id)
    assert_equal [ future.id ], Compensation.effective_on(Date.new(2027, 1, 1)).pluck(:id)
  end

  test "salary versions cannot be changed or removed" do
    salary = @employee.compensations.create!(@attributes.merge(user: @user))
    assert_not salary.update(reason: "Rewritten")
    assert_not salary.destroy
  end

  test "duplicate effective dates are rejected" do
    @employee.compensations.create!(@attributes.merge(user: @user))
    assert_not @employee.compensations.new(@attributes.merge(user: @user)).valid?
  end

  test "stale salary writes fail without creating a record" do
    RecordCompensation.call(employee: @employee, user: @user, attributes: @attributes, expected_version: 0)
    assert_raises(ActiveRecord::StaleObjectError) do
      RecordCompensation.call(employee: @employee, user: @user, attributes: @attributes.merge(effective_on: "2027-01-01"), expected_version: 0)
    end
    assert_equal 1, @employee.compensations.count
  end

  test "monthly rounding difference is explicitly exposed" do
    salary = @employee.compensations.create!(@attributes.merge(user: @user, annual_ctc: "1", components: { "Basic" => "0.5", "Other" => "0.5" }))
    assert_equal BigDecimal("0.08"), salary.monthly_ctc
    assert_equal "0.0", salary.summary[:rounding_adjustment]
    salary = @employee.compensations.new(@attributes.merge(user: @user, annual_ctc: "2", components: { "Basic" => "1", "Other" => "1" }))
    assert_equal "0.01", salary.summary[:rounding_adjustment]
  end

  test "JPY does not allow fractional units" do
    salary = @employee.compensations.new(@attributes.merge(user: @user, currency: "JPY", annual_ctc: "1.5", components: { "Basic" => "1.5" }))
    assert_not salary.valid?
  end
  test "JPY summary serializes rounded integer monthly amounts" do
    salary = @employee.compensations.create!(@attributes.merge(user: @user, currency: "JPY"))
    assert_equal "100000.0", salary.summary[:monthly_ctc]
    assert_equal "40000.0", salary.summary[:monthly_components]["Basic"]
  end

  test "annual CTC cannot silently round excess decimal places" do
    salary = @employee.compensations.new(@attributes.merge(user: @user, annual_ctc: "1200000.001"))
    assert_not salary.valid?
  end
end
