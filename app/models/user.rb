class User < ApplicationRecord
  has_secure_password
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 12 }, allow_nil: true
end
