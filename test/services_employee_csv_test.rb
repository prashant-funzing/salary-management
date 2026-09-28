require "test_helper"

class EmployeeCsvTest < ActiveSupport::TestCase
  setup { @user = User.create!(email: "import@example.com", password: "TestPassword123!") }

  test "imports a valid file and rejects duplicate reruns" do
    csv = File.read(Rails.root.join("public/import-template.csv"))
    assert_equal 1, EmployeeCsv.import(csv, user: @user).count
    assert_equal 0, EmployeeCsv.import(csv, user: @user).count
    assert_equal 1, Employee.count
    assert_equal 1, Compensation.count
  end

  test "invalid row rolls back the entire import" do
    csv = File.read(Rails.root.join("public/import-template.csv"))
    invalid = CSV.parse(csv)[1]
    invalid[0] = "NEW-002"
    invalid[2] = "second@example.com"
    invalid[8] = "1"
    result = EmployeeCsv.import(csv + CSV.generate_line(invalid), user: @user)
    assert_equal 0, result.count
    assert_match "Row 3", result.errors.first
    assert_equal 0, Employee.count
  end

  test "exports neutralize spreadsheet formulas" do
    assert_equal "'=SUM(A1)", EmployeeCsv.safe_cell("=SUM(A1)")
    assert_equal "Asha", EmployeeCsv.safe_cell("Asha")
  end
end
