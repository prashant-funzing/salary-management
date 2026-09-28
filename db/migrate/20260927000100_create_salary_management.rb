class CreateSalaryManagement < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :country, null: false
      t.string :department, null: false
      t.string :level, null: false
      t.string :status, null: false, default: 'active'
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, [ :country, :department, :level ]
    add_index :employees, :status
    add_check_constraint :employees, "status IN ('active', 'inactive')", name: 'employee_status'
    create_table :compensations do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :effective_on, null: false
      t.string :currency, null: false
      t.decimal :annual_ctc, precision: 18, scale: 2, null: false
      t.jsonb :components, null: false, default: {}
      t.string :reason, null: false
      t.timestamps
    end
    add_index :compensations, [ :employee_id, :effective_on ], unique: true
    add_check_constraint :compensations, 'annual_ctc > 0', name: 'positive_ctc'
    add_check_constraint :compensations, "currency IN ('INR', 'USD', 'GBP', 'EUR', 'CAD', 'SGD', 'JPY')", name: 'supported_currency'
  end
end
