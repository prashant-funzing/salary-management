module Api
  class ReportsController < BaseController
    def index
      date = params[:as_of].present? ? Date.iso8601(params[:as_of]) : Date.current
      employees = EmployeeQuery.call(params).where(status: "active")
      salaries = Compensation.effective_on(date).where(employee_id: employees.select(:id))
      # Rank within each currency so even-sized medians use exact numeric AVG,
      # avoiding percentile_cont's floating-point conversion of money.
      ranked = salaries.select("currency, annual_ctc, ROW_NUMBER() OVER (PARTITION BY currency ORDER BY annual_ctc) AS position, COUNT(*) OVER (PARTITION BY currency) AS population")
      totals = Compensation.from("(#{ranked.to_sql}) ranked").group(:currency).pluck(:currency,
        Arel.sql("COUNT(*)"), Arel.sql("SUM(annual_ctc)"),
        Arel.sql("AVG(annual_ctc) FILTER (WHERE position IN ((population + 1) / 2, (population + 2) / 2))"))
      dimension = %w[country department level].include?(params[:group_by]) ? params[:group_by] : "department"
      groups = salaries.joins(:employee).group("employees.#{dimension}", :currency).sum(:annual_ctc)
      render json: { planning_equivalent: ReportingRates.convert(totals), as_of: date, headcount: employees.count, compensated_headcount: salaries.count,
        totals: totals.map { |currency, count, total, median| { currency: currency, count: count, annual_ctc: total.to_s("F"), median: median.to_s("F") } },
        groups: groups.map { |(name, currency), total| { name: name, currency: currency, annual_ctc: total.to_s("F") } },
        note: "Active workforce today, using salaries effective on the selected date. Currencies are reported separately." }
    end
  end
end
