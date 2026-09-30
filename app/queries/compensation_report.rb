class CompensationReport
  GROUPING_FIELDS = %w[country department level].freeze
  NOTE = "Active workforce today, using salaries effective on the selected date. Currencies are reported separately.".freeze

  def initialize(employees:, as_of:, group_by:)
    @employees = employees.where(status: "active")
    @as_of = as_of
    @group_by = GROUPING_FIELDS.include?(group_by) ? group_by : "department"
    @salaries = Compensation.effective_on(as_of).where(employee_id: @employees.select(:id))
  end

  def call
    totals = currency_totals

    {
      planning_equivalent: ReportingRates.convert(totals),
      as_of: @as_of,
      headcount: @employees.count,
      compensated_headcount: @salaries.count,
      totals: totals.map { |row| format_total(*row) },
      groups: grouped_totals,
      note: NOTE
    }
  end

  private

  def currency_totals
    # Rank in PostgreSQL numeric precision: percentile_cont converts money to floats.
    ranked = @salaries.select(<<~SQL.squish)
      currency,
      annual_ctc,
      ROW_NUMBER() OVER (PARTITION BY currency ORDER BY annual_ctc) AS position,
      COUNT(*) OVER (PARTITION BY currency) AS population
    SQL

    median = <<~SQL.squish
      AVG(annual_ctc) FILTER (
        WHERE position IN ((population + 1) / 2, (population + 2) / 2)
      )
    SQL

    Compensation.from("(#{ranked.to_sql}) ranked").group(:currency).pluck(
      :currency,
      Arel.sql("COUNT(*)"),
      Arel.sql("SUM(annual_ctc)"),
      Arel.sql(median)
    )
  end

  def format_total(currency, count, total, median)
    {
      currency: currency,
      count: count,
      annual_ctc: total.to_s("F"),
      median: median.to_s("F")
    }
  end

  def grouped_totals
    totals = @salaries.joins(:employee)
      .group("employees.#{@group_by}", :currency)
      .sum(:annual_ctc)

    totals.map do |(name, currency), total|
      { name: name, currency: currency, annual_ctc: total.to_s("F") }
    end
  end
end
