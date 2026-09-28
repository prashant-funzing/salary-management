require "csv"

class EmployeeCsv
  HEADERS = %w[employee_code name email country department level status currency annual_ctc effective_on reason components].freeze
  MAX_BYTES = 5.megabytes
  Result = Data.define(:count, :errors)

  def self.import(content, user:)
    return Result.new(0, [ "File exceeds 5 MB" ]) if content.bytesize > MAX_BYTES
    table = CSV.parse(content.delete_prefix("\uFEFF"), headers: true)
    return Result.new(0, [ "Headers must be: #{HEADERS.join(',')}" ]) unless table.headers == HEADERS
    return Result.new(0, [ "File must contain 1–10000 rows" ]) unless table.size.between?(1, 10_000)
    errors = []
    Employee.transaction do
      table.each_with_index do |row, index|
        begin
          Employee.transaction(requires_new: true) do
            attributes = row.to_h
            employee = Employee.create!(attributes.slice(*HEADERS.first(7)))
            employee.compensations.create!(user: user, currency: attributes["currency"], annual_ctc: attributes["annual_ctc"], effective_on: attributes["effective_on"], reason: attributes["reason"], components: JSON.parse(attributes["components"].to_s))
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, JSON::ParserError => error
          message = error.is_a?(ActiveRecord::RecordInvalid) ? error.record.errors.full_messages.join(", ") : "Duplicate employee or invalid components JSON"
          errors << "Row #{index + 2}: #{message}"
          break if errors.size >= 50
        end
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    Result.new(errors.empty? ? table.size : 0, errors)
  rescue CSV::MalformedCSVError, ArgumentError
    Result.new(0, [ "Malformed CSV. Check quoting and UTF-8 encoding." ])
  end

  def self.export(scope)
    CSV.generate do |csv|
      csv << HEADERS
      scope.find_in_batches(batch_size: 500) do |employees|
        salaries = Compensation.effective_on(Date.current).where(employee_id: employees.map(&:id)).index_by(&:employee_id)
        employees.each do |employee|
          salary = salaries[employee.id]
          values = HEADERS.first(7).map { |key| employee.public_send(key) }
          values += [ salary&.currency, salary&.annual_ctc&.to_s("F"), salary&.effective_on, salary&.reason, salary&.components&.to_json ]
          csv << values.map { |value| safe_cell(value) }
        end
      end
    end
  end

  def self.safe_cell(value)
    text = value.to_s
    text.match?(/\A[\s]*[=+@-]/) ? "'#{text}" : text
  end
end
