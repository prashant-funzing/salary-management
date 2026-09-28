# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_27_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "compensations", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "user_id", null: false
    t.date "effective_on", null: false
    t.string "currency", null: false
    t.decimal "annual_ctc", precision: 18, scale: 2, null: false
    t.jsonb "components", default: {}, null: false
    t.string "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "effective_on"], name: "index_compensations_on_employee_id_and_effective_on", unique: true
    t.index ["employee_id"], name: "index_compensations_on_employee_id"
    t.index ["user_id"], name: "index_compensations_on_user_id"
    t.check_constraint "annual_ctc > 0::numeric", name: "positive_ctc"
    t.check_constraint "currency::text = ANY (ARRAY['INR'::character varying, 'USD'::character varying, 'GBP'::character varying, 'EUR'::character varying, 'CAD'::character varying, 'SGD'::character varying, 'JPY'::character varying]::text[])", name: "supported_currency"
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "country", null: false
    t.string "department", null: false
    t.string "level", null: false
    t.string "status", default: "active", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country", "department", "level"], name: "index_employees_on_country_and_department_and_level"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["status"], name: "index_employees_on_status"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])", name: "employee_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "compensations", "employees"
  add_foreign_key "compensations", "users"
end
