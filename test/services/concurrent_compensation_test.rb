require "test_helper"

class ConcurrentCompensationTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "two simultaneous HR updates produce one salary and one conflict" do
    user = User.create!(email: "concurrent@example.com", password: "TestPassword123!")
    employee = create_employee("CONCURRENT")
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          record = Employee.find(employee.id)
          ready << true
          start.pop
          begin
            RecordCompensation.call(employee: record, user: user, attributes: salary_attributes, expected_version: 0)
            results << :created
          rescue ActiveRecord::StaleObjectError
            results << :conflict
          rescue => error
            results << error
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each { |thread| assert thread.join(10), "Concurrent write did not finish" }
    assert_equal [ :conflict, :created ], 2.times.map { results.pop }.sort
    assert_equal 1, employee.compensations.count
    assert_equal 1, employee.reload.lock_version
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
    if employee
      Compensation.where(employee_id: employee.id).delete_all
      Employee.where(id: employee.id).delete_all
    end
    User.where(id: user.id).delete_all if user
  end
end
