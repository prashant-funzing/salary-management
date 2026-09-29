# Both employee edits and compensation changes use the same optimistic lock token.
class LockVersion
  def self.parse(value)
    unless value.to_s.match?(/\A[0-9]+\z/)
      raise ArgumentError, "lock_version must be a non-negative integer"
    end
    Integer(value.to_s, 10)
  end
end
