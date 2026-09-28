require "test_helper"

class EmployeeCsvValidationTest < ActiveSupport::TestCase
  setup do
    @user = create_hr
    @template = File.read(Rails.root.join("public/import-template.csv"))
  end

  test "UTF8 BOM and Windows line endings are accepted" do
    result = EmployeeCsv.import("\uFEFF" + @template.gsub("\n", "\r\n"), user: @user)
    assert_empty result.errors
    assert_equal 1, result.count
  end

  test "wrong headers empty file malformed quoting and size limits are rejected" do
    inputs = [ "", "name,email\nAsha,asha@example.com\n", CSV.generate_line(EmployeeCsv::HEADERS), @template + '"unterminated', "x" * (EmployeeCsv::MAX_BYTES + 1) ]
    inputs.each do |content|
      result = EmployeeCsv.import(content, user: @user)
      assert_equal 0, result.count
      assert result.errors.any?
    end
    assert_equal 0, Employee.count
  end

  test "more than ten thousand rows are rejected before any writes" do
    row = CSV.parse(@template).last
    content = CSV.generate_line(EmployeeCsv::HEADERS) + CSV.generate_line(row) * 10_001
    assert_no_difference("Employee.count") do
      result = EmployeeCsv.import(content, user: @user)
      assert_includes result.errors.first, "10000"
    end
  end

  test "malformed component JSON reports a row and rolls back employee creation" do
    row = CSV.parse(@template).last
    row[-1] = "not json"
    result = EmployeeCsv.import(CSV.generate_line(EmployeeCsv::HEADERS) + CSV.generate_line(row), user: @user)
    assert_match "Row 2", result.errors.first
    assert_equal 0, Employee.count
    assert_equal 0, Compensation.count
  end

  test "errors are capped at fifty and nothing is partially imported" do
    row = CSV.parse(@template).last
    row[2] = "invalid email"
    content = CSV.generate_line(EmployeeCsv::HEADERS) + CSV.generate_line(row) * 60
    result = EmployeeCsv.import(content, user: @user)
    assert_equal 50, result.errors.size
    assert_equal 0, Employee.count
  end

  test "exports use current salary exclude future versions and preserve unpaid employees" do
    travel_to Time.utc(2026, 6, 1) do
      employee = create_employee(name: "=formula")
      create_salary(employee, @user)
      create_salary(employee, @user, effective_on: "2027-01-01", annual_ctc: "2400000", components: { "Basic" => "2400000" })
      create_employee("UNPAID")
      rows = CSV.parse(EmployeeCsv.export(Employee.all), headers: true)
      assert_equal 2, rows.size
      assert_equal "'=formula", rows.first["name"]
      assert_equal "1200000.0", rows.first["annual_ctc"]
      assert_equal "480000", JSON.parse(rows.first["components"])["Basic"]
      assert rows[1]["annual_ctc"].blank?
    end
  end

  test "spreadsheet formula prefixes including leading whitespace are neutralized" do
    [ "=A1", "+A1", "-A1", "@SUM(A1)", "\t=A1", "  =A1" ].each do |value|
      assert_equal "'#{value}", EmployeeCsv.safe_cell(value)
    end
  end
end
