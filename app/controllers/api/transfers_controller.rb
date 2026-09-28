module Api
  class TransfersController < BaseController
    def create
      content = params.require(:csv)
      raise ArgumentError, "CSV must be text" unless content.is_a?(String)
      result = EmployeeCsv.import(content, user: current_user)
      render json: { count: result.count, errors: result.errors }, status: result.errors.empty? ? :created : :unprocessable_entity
    end

    def index
      send_data EmployeeCsv.export(EmployeeQuery.call(params)), filename: "acme-employees-#{Date.current}.csv", type: "text/csv"
    end
  end
end
