module Api
  class CompensationsController < BaseController
    def create
      salary = RecordCompensation.call(
        employee: Employee.find(params[:employee_id]),
        user: current_user,
        attributes: compensation_params.to_h,
        expected_version: params.require(:lock_version)
      )

      render json: salary.summary, status: :created
    end

    private

    def compensation_params
      params.expect(compensation: [
        :effective_on, :currency, :annual_ctc, :reason, { components: {} }
      ])
    end
  end
end
