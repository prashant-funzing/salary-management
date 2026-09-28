require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "full seed creates ten thousand employees and reruns preserve HR changes" do
    previous = ENV.to_h.slice("ADMIN_EMAIL", "ADMIN_PASSWORD")
    ENV["ADMIN_EMAIL"] = "seed@example.com"
    ENV["ADMIN_PASSWORD"] = "SeedPassword123!"
    capture_io { load Rails.root.join("db/seeds.rb") }
    assert_equal 10_000, Employee.count
    assert_equal 20_000, Compensation.count
    assert_equal Compensation::CURRENCIES.sort, Compensation.distinct.pluck(:currency).sort
    assert_equal 7, Employee.distinct.count(:country)
    assert Compensation.pluck(:annual_ctc, :components).all? { |annual, components| components.values.sum { |amount| BigDecimal(amount) } == annual }
    employee = Employee.find_by!(employee_code: "ACME-00001")
    original_ids = employee.compensations.order(:id).pluck(:id)
    employee.update!(name: "HR corrected name", status: "inactive")
    user = User.find_by!(email: "seed@example.com")
    user.update!(password: "ChangedPassword123!")
    salary = create_salary(employee, user, effective_on: "2027-01-01")
    capture_io { load Rails.root.join("db/seeds.rb") }
    assert_equal 10_000, Employee.count
    assert_equal 20_001, Compensation.count
    assert_equal "HR corrected name", employee.reload.name
    assert_equal "inactive", employee.status
    assert_equal original_ids + [ salary.id ], employee.compensations.order(:id).pluck(:id)
    assert user.reload.authenticate("ChangedPassword123!")
  ensure
    %w[ADMIN_EMAIL ADMIN_PASSWORD].each { |key| previous.key?(key) ? ENV[key] = previous[key] : ENV.delete(key) }
  end
end
