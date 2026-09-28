class Employee < ApplicationRecord
  has_many :compensations, dependent: :restrict_with_exception
  validates :employee_code, :name, :email, :country, :department, :level, presence: true, length: { maximum: 120 }
  validates :employee_code, :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[active inactive] }
  normalizes :email, with: ->(value) { value.strip.downcase }
end
