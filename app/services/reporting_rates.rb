# Illustrative planning assumptions for synthetic demo data, not market FX rates.
class ReportingRates
  AS_OF = "2026-01-01".freeze
  INR_PER_UNIT = { "INR" => "1", "USD" => "85", "GBP" => "110", "EUR" => "95", "CAD" => "62", "SGD" => "65", "JPY" => "0.6" }.freeze

  def self.convert(totals)
    total = totals.sum(BigDecimal("0")) { |currency, _, amount, _| amount * BigDecimal(INR_PER_UNIT.fetch(currency)) }
    { currency: "INR", annual_ctc: total.round(2).to_s("F"), as_of: AS_OF, rates: INR_PER_UNIT,
      note: "Illustrative planning rates dated 2026-01-01; not live or historical market rates. Local currency totals are authoritative." }
  end
end
