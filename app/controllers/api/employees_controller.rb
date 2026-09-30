module Api
  class EmployeesController < BaseController
    def index
      directory = EmployeeDirectory.new(
        employees: EmployeeQuery.call(params),
        page: params.fetch(:page, 1)
      )

      render json: directory.call
    end

    def show
      employee = Employee.find(params[:id])
      history = employee.compensations.includes(:user).order(effective_on: :desc)

      render json: employee.as_json.merge(history: history.map(&:summary))
    end

    def create
      render json: Employee.create!(employee_params), status: :created
    end

    def update
      employee = Employee.find(params[:id])
      attributes = employee_params
      attributes[:lock_version] = LockVersion.parse(attributes.require(:lock_version))

      employee.update!(attributes)

      render json: employee
    end

    def options
      filters = %w[country department level].to_h do |field|
        [ field, Employee.distinct.order(field).pluck(field) ]
      end

      render json: filters.merge(currencies: Compensation::CURRENCIES)
    end

    private

    def employee_params
      params.expect(employee: [
        :employee_code, :name, :email, :country, :department, :level, :status, :lock_version
      ])
    end
  end
end
