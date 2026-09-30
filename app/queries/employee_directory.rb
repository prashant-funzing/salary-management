class EmployeeDirectory
  PER_PAGE = 25

  def initialize(employees:, page:)
    @employees = employees
    @page = [ page.to_i, 1 ].max
  end

  def call
    employees = @employees.order(:id).limit(PER_PAGE).offset((@page - 1) * PER_PAGE).to_a
    salaries = current_salaries(employees)

    {
      employees: employees.map do |employee|
        employee.as_json.merge(compensation: salaries[employee.id]&.summary)
      end,
      total: @employees.count,
      page: @page,
      per_page: PER_PAGE
    }
  end

  private

  def current_salaries(employees)
    Compensation.effective_on(Date.current)
      .where(employee_id: employees.map(&:id))
      .includes(:user)
      .index_by(&:employee_id)
  end
end
