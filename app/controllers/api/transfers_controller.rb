module Api
  class TransfersController < BaseController
    def create
      result = EmployeeCsv.import(csv_content, user: current_user)
      status = result.errors.empty? ? :created : :unprocessable_entity

      render json: { count: result.count, errors: result.errors }, status: status
    end

    def index
      send_data EmployeeCsv.export(EmployeeQuery.call(params)),
        filename: "acme-employees-#{Date.current}.csv",
        type: "text/csv"
    end

    private

    def csv_content
      content = params.require(:csv)
      raise ArgumentError, "CSV must be text" unless content.is_a?(String)

      content
    end
  end
end
