# Only the disposable browser-test database may be cleared.
unless Rails.env.test? && ActiveRecord::Base.connection_db_config.database == "salary_management_tdd_browser_test"
  abort "Refusing to clear a database other than salary_management_tdd_browser_test in test mode"
end
Employee.transaction do
  Compensation.delete_all
  Employee.delete_all
  User.delete_all
  load Rails.root.join("db/seeds.rb")
end
