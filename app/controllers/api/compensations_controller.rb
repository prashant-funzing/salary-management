module Api
  class CompensationsController < BaseController
    def create
      employee = Employee.find(params[:employee_id])
      attributes = params.expect(compensation: [ :effective_on, :currency, :annual_ctc, :reason, { components: {} } ]).to_h
      salary = RecordCompensation.call(employee: employee, user: current_user, attributes: attributes, expected_version: params.require(:lock_version))
      render json: salary.summary, status: :created
    end
  end
end
