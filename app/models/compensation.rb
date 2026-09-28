class Compensation < ApplicationRecord
  CURRENCIES = %w[INR USD GBP EUR CAD SGD JPY].freeze
  belongs_to :employee
  belongs_to :user
  validates :effective_on, :reason, presence: true
  validates :reason, length: { maximum: 500 }
  validates :currency, inclusion: { in: CURRENCIES }
  validates :annual_ctc, numericality: { greater_than: 0, less_than: 10**14 }
  validates :effective_on, uniqueness: { scope: :employee_id }
  validate :validate_components
  before_update { throw :abort }
  before_destroy { throw :abort }

  def self.effective_on(date)
    where("effective_on <= ?", date).where(<<~SQL.squish, date)
      NOT EXISTS (SELECT 1 FROM compensations newer
        WHERE newer.employee_id = compensations.employee_id
        AND newer.effective_on <= ? AND newer.effective_on > compensations.effective_on)
    SQL
  end

  def precision
    currency == "JPY" ? 0 : 2
  end

  def monthly_ctc
    BigDecimal((annual_ctc / 12).round(precision).to_s)
  end

  def summary
    monthly = components.transform_values { |amount| BigDecimal((BigDecimal(amount.to_s) / 12).round(precision).to_s).to_s("F") }
    { id: id, annual_ctc: annual_ctc.to_s("F"), monthly_ctc: monthly_ctc.to_s("F"),
      currency: currency, effective_on: effective_on, reason: reason, components: components,
      monthly_components: monthly,
      rounding_adjustment: (monthly_ctc - monthly.values.sum { |v| BigDecimal(v) }).to_s("F"),
      created_at: created_at, recorded_by: user.email }
  end

  private

  def validate_components
    raw_total = BigDecimal(annual_ctc_before_type_cast.to_s, exception: false)
    if raw_total && (!raw_total.finite? || raw_total != raw_total.round(precision))
      errors.add(:annual_ctc, "exceeds currency precision")
    end
    unless components.is_a?(Hash) && components.size.between?(1, 20)
      errors.add(:components, "must contain between 1 and 20 named amounts")
      return
    end
    amounts = components.map do |name, value|
      amount = BigDecimal(value.to_s, exception: false)
      if name.strip.empty? || name.length > 80 || !amount&.finite? || amount.negative? || amount != amount.round(precision)
        errors.add(:components, "must have valid names and non-negative amounts at currency precision")
        return
      end
      amount
    end
    errors.add(:components, "must sum exactly to annual CTC") unless amounts.sum == annual_ctc
    errors.add(:annual_ctc, "exceeds currency precision") if annual_ctc && annual_ctc != annual_ctc.round(precision)
  end
end
