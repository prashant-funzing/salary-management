class RecordCompensation
  def self.call(employee:, user:, attributes:, expected_version:)
    version = parse_version(expected_version)
    employee.with_lock do
      raise ActiveRecord::StaleObjectError.new(employee, "update") unless employee.lock_version == version
      compensation = employee.compensations.create!(attributes.merge(user: user))
      employee.touch
      compensation
    end
  end
  def self.parse_version(value)
    unless value.to_s.match?(/\A[0-9]+\z/)
      raise ArgumentError, "lock_version must be a non-negative integer"
    end
    Integer(value.to_s, 10)
  end
end
