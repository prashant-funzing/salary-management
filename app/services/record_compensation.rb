class RecordCompensation
  def self.call(employee:, user:, attributes:, expected_version:)
    version = LockVersion.parse(expected_version)

    employee.with_lock do
      raise ActiveRecord::StaleObjectError.new(employee, "update") unless employee.lock_version == version

      compensation = employee.compensations.create!(attributes.merge(user: user))
      employee.touch

      compensation
    end
  end
end
