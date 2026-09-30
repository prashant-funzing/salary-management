# Deterministic synthetic data. Safe to rerun; never deletes or overwrites HR edits.
email = ENV.fetch("ADMIN_EMAIL", "hr@acme.example")
password = ENV.fetch("ADMIN_PASSWORD") do
  raise "Set ADMIN_PASSWORD" if Rails.env.production?

  "AcmeDemo2026!"
end
user = User.find_or_create_by!(email: email) { |admin| admin.password = password }

countries = [
  [ "India", "INR", 1_200_000 ],
  [ "United States", "USD", 90_000 ],
  [ "United Kingdom", "GBP", 65_000 ],
  [ "Germany", "EUR", 70_000 ],
  [ "Singapore", "SGD", 100_000 ],
  [ "Canada", "CAD", 85_000 ],
  [ "Japan", "JPY", 8_000_000 ]
]
departments = %w[Engineering Product Design Finance Sales Operations People]
first_names = %w[Aarav Aisha Oliver Emma Liam Sophia Arjun Maya Noah Mia Kabir Hana Lucas Yuki Priya Ethan Zara Rohan Mei Ava]
last_names = %w[Sharma Patel Singh Williams Chen Tanaka Brown Wilson Kumar Garcia Martin Lee Taylor Roy Shah]
now = Time.utc(2026, 1, 1)

Employee.transaction do
  (1..10_000).each_slice(500) do |numbers|
    rows = numbers.map do |employee_number|
      country, = countries[(employee_number - 1) % countries.size]
      {
        employee_code: format("ACME-%05d", employee_number),
        name: "#{first_names[(employee_number - 1) % first_names.size]} #{last_names[(employee_number / first_names.size) % last_names.size]}",
        email: "employee#{employee_number}@acme.example",
        country: country,
        department: departments[(employee_number / 7) % departments.size],
        level: "L#{1 + employee_number % 6}",
        status: "active",
        created_at: now,
        updated_at: now
      }
    end

    Employee.insert_all(rows, unique_by: :employee_code)
  end

  Employee.where("employee_code LIKE ?", "ACME-%").find_in_batches(batch_size: 500) do |employees|
    rows = employees.flat_map do |employee|
      employee_number = employee.employee_code.delete_prefix("ACME-").to_i
      next [] unless employee_number.between?(1, 10_000)

      _, currency, base = countries[(employee_number - 1) % countries.size]
      annual = (base * (80 + employee_number % 100) / 1000) * 10

      [ Date.new(2025, 1, 1), Date.new(2026, 1, 1) ].each_with_index.map do |date, version_index|
        total = version_index.zero? ? annual * 9 / 100 * 10 : annual
        basic = total * 4 / 10
        hra = total * 2 / 10

        {
          employee_id: employee.id,
          user_id: user.id,
          effective_on: date,
          currency: currency,
          annual_ctc: total,
          components: {
            "Basic" => basic.to_s,
            "HRA" => hra.to_s,
            "Special Allowance" => (total - basic - hra).to_s
          },
          reason: version_index.zero? ? "Initial compensation" : "Annual evaluation",
          created_at: now,
          updated_at: now
        }
      end
    end

    Compensation.insert_all(rows, unique_by: [ :employee_id, :effective_on ])
  end
end

puts "Seed complete: #{Employee.count} employees, #{Compensation.count} compensation versions."
