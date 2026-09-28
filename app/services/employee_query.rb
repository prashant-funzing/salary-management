class EmployeeQuery
  def self.call(params)
    scope = Employee.all
    if params[:q].present?
      query = "%#{Employee.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where("name ILIKE :q OR email ILIKE :q OR employee_code ILIKE :q", q: query)
    end
    %w[country department level status].each do |field|
      scope = scope.where(field => params[field]) if params[field].present?
    end
    scope
  end
end
