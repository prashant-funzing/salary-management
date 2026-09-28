require "test_helper"

class CompensationValidationTest < ActiveSupport::TestCase
  setup do
    @employee = create_employee
    @user = create_hr
  end

  test "invalid totals are rejected without exceptions or coercion" do
    [ nil, "", "abc", "1200000oops", "NaN", "Infinity", "-Infinity", "0", "-1", "100000000000000" ].each do |amount|
      salary = @employee.compensations.new(salary_attributes(annual_ctc: amount).merge(user: @user))
      assert_not salary.valid?, amount.inspect
    end
  end

  test "component shape size names precision and values are validated" do
    invalid = [ nil, [], {}, "text", { " " => "1200000" }, { "x" * 81 => "1200000" },
      { "Basic" => nil }, { "Basic" => [] }, { "Basic" => "1199999.999", "Other" => "0.001" },
      (1..21).to_h { |i| [ "Component #{i}", "0" ] } ]
    invalid.each do |components|
      salary = @employee.compensations.new(salary_attributes(components: components).merge(user: @user))
      assert_not salary.valid?, components.inspect
    end
  end

  test "currency date and reason are required" do
    [ { currency: "XYZ" }, { effective_on: "bad" }, { reason: "" }, { reason: "x" * 501 } ].each do |overrides|
      assert_not @employee.compensations.new(salary_attributes(**overrides).merge(user: @user)).valid?
    end
  end

  test "all supported currencies serialize and reconcile their monthly components" do
    Compensation::CURRENCIES.each do |currency|
      salary = @employee.compensations.new(salary_attributes(currency: currency).merge(user: @user))
      assert salary.valid?, currency
      summary = salary.summary
      total = summary[:monthly_components].values.sum { |amount| BigDecimal(amount) } + BigDecimal(summary[:rounding_adjustment])
      assert_equal BigDecimal(summary[:monthly_ctc]), total, currency
    end
  end

  test "zero valued components are valid when total CTC remains positive" do
    assert create_salary(@employee, @user, components: { "Basic" => "1200000", "HRA" => "0" }).persisted?
  end

  test "effective salary selection is isolated between employees" do
    first = create_salary(@employee, @user)
    second = create_salary(create_employee("E2"), @user, effective_on: "2026-02-01")
    assert_equal [ first.id ], Compensation.effective_on(Date.new(2026, 1, 15)).pluck(:id)
    assert_equal [ first.id, second.id ].sort, Compensation.effective_on(Date.new(2026, 2, 1)).pluck(:id).sort
  end
  test "negative monthly rounding adjustment is explicitly reconciled" do
    salary = create_salary(@employee, @user, annual_ctc: "1", components: { "Basic" => "0.1", "HRA" => "0.1", "Other" => "0.8" })
    assert_equal "-0.01", salary.summary[:rounding_adjustment]
    assert_equal "0.08", salary.summary[:monthly_ctc]
  end

  test "backdated entry never replaces a later effective salary and currency is versioned" do
    latest = create_salary(@employee, @user, currency: "USD", effective_on: "2026-06-01")
    earlier = create_salary(@employee, @user, currency: "INR", effective_on: "2026-01-01")
    assert_equal [ earlier.id ], Compensation.effective_on(Date.new(2026, 5, 31)).pluck(:id)
    assert_equal [ latest.id ], Compensation.effective_on(Date.new(2026, 6, 1)).pluck(:id)
    assert_equal "INR", earlier.reload.currency
    assert_equal "USD", latest.reload.currency
  end
end
