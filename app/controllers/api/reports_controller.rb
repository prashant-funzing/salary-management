module Api
  class ReportsController < BaseController
    def index
      report = CompensationReport.new(
        employees: EmployeeQuery.call(params),
        as_of: report_date,
        group_by: params[:group_by]
      )

      render json: report.call
    end

    private

    def report_date
      params[:as_of].present? ? Date.iso8601(params[:as_of]) : Date.current
    end
  end
end
