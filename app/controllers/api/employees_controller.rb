module Api
  class EmployeesController < BaseController
    def index
      scope = EmployeeQuery.call(params)
      page = [ params.fetch(:page, 1).to_i, 1 ].max
      employees = scope.order(:id).limit(25).offset((page - 1) * 25).to_a
      salaries = Compensation.effective_on(Date.current).where(employee_id: employees.map(&:id)).includes(:user).index_by(&:employee_id)
      render json: { employees: employees.map { |e| e.as_json.merge(compensation: salaries[e.id]&.summary) }, total: scope.count, page: page, per_page: 25 }
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
      render json: %w[country department level].to_h { |field| [ field, Employee.distinct.order(field).pluck(field) ] }.merge(currencies: Compensation::CURRENCIES)
    end

    private

    def employee_params
      params.expect(employee: [ :employee_code, :name, :email, :country, :department, :level, :status, :lock_version ])
    end
  end
end
