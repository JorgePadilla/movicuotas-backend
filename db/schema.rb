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

ActiveRecord::Schema[8.1].define(version: 2025_12_19_034125) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.jsonb "change_details"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.string "contract_document_filename"
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.text "notes"
    t.string "signature_image_filename"
    t.datetime "signed_at"
    t.string "signed_by_name"
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_contracts_on_loan_id", unique: true
  end

  create_table "credit_applications", force: :cascade do |t|
    t.string "application_number", null: false
    t.decimal "approved_amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "employment_status"
    t.text "notes"
    t.string "rejection_reason"
    t.string "salary_range"
    t.string "selected_color"
    t.string "selected_imei"
    t.bigint "selected_phone_model_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.string "verification_method"
    t.index ["application_number"], name: "index_credit_applications_on_application_number", unique: true
    t.index ["customer_id"], name: "index_credit_applications_on_customer_id"
    t.index ["selected_phone_model_id"], name: "index_credit_applications_on_selected_phone_model_id"
    t.index ["status"], name: "index_credit_applications_on_status"
    t.index ["vendor_id"], name: "index_credit_applications_on_vendor_id"
  end

  create_table "customers", force: :cascade do |t|
    t.text "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "department"
    t.string "email"
    t.string "full_name", null: false
    t.string "gender"
    t.string "identification_number", null: false
    t.text "notes"
    t.string "phone", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["identification_number"], name: "index_customers_on_identification_number", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.string "brand", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.string "imei", null: false
    t.bigint "loan_id", null: false
    t.string "lock_status", default: "unlocked"
    t.datetime "locked_at"
    t.bigint "locked_by_id"
    t.string "model", null: false
    t.text "notes"
    t.bigint "phone_model_id", null: false
    t.datetime "updated_at", null: false
    t.index ["imei"], name: "index_devices_on_imei", unique: true
    t.index ["loan_id"], name: "index_devices_on_loan_id"
    t.index ["lock_status"], name: "index_devices_on_lock_status"
    t.index ["locked_by_id"], name: "index_devices_on_locked_by_id"
    t.index ["phone_model_id"], name: "index_devices_on_phone_model_id"
  end

  create_table "installments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.integer "installment_number", null: false
    t.decimal "late_fee", precision: 10, scale: 2, default: "0.0"
    t.bigint "loan_id", null: false
    t.text "notes"
    t.decimal "paid_amount", precision: 10, scale: 2, default: "0.0"
    t.date "paid_date"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date", "status"], name: "index_installments_on_due_date_and_status"
    t.index ["due_date"], name: "index_installments_on_due_date"
    t.index ["loan_id", "installment_number"], name: "index_installments_on_loan_id_and_installment_number", unique: true
    t.index ["loan_id"], name: "index_installments_on_loan_id"
    t.index ["status"], name: "index_installments_on_status"
  end

  create_table "loans", force: :cascade do |t|
    t.decimal "approved_amount", precision: 10, scale: 2, null: false
    t.string "branch_number", null: false
    t.string "contract_number", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.decimal "down_payment_amount", precision: 10, scale: 2, null: false
    t.decimal "down_payment_percentage", precision: 5, scale: 2, null: false
    t.date "end_date"
    t.decimal "financed_amount", precision: 10, scale: 2, null: false
    t.decimal "interest_rate", precision: 5, scale: 2, null: false
    t.text "notes"
    t.integer "number_of_installments", null: false
    t.date "start_date", null: false
    t.string "status", default: "active", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["branch_number"], name: "index_loans_on_branch_number"
    t.index ["contract_number"], name: "index_loans_on_contract_number", unique: true
    t.index ["customer_id"], name: "index_loans_on_customer_id"
    t.index ["status"], name: "index_loans_on_status"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "mdm_blueprints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "device_id", null: false
    t.datetime "generated_at"
    t.text "qr_code_data"
    t.string "qr_code_image_filename"
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_mdm_blueprints_on_device_id", unique: true
    t.index ["status"], name: "index_mdm_blueprints_on_status"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.text "metadata"
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.datetime "sent_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_notifications_on_customer_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["sent_at"], name: "index_notifications_on_sent_at"
  end

  create_table "payment_installments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "installment_id", null: false
    t.bigint "payment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["installment_id"], name: "index_payment_installments_on_installment_id"
    t.index ["payment_id", "installment_id"], name: "index_payment_installments_on_payment_id_and_installment_id", unique: true
    t.index ["payment_id"], name: "index_payment_installments_on_payment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.text "notes"
    t.date "payment_date", null: false
    t.string "payment_method", null: false
    t.string "reference_number"
    t.datetime "updated_at", null: false
    t.string "verification_status", default: "pending"
    t.index ["loan_id"], name: "index_payments_on_loan_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["verification_status"], name: "index_payments_on_verification_status"
  end

  create_table "phone_models", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "brand", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.string "image_url"
    t.string "model", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "storage"
    t.datetime "updated_at", null: false
    t.index ["brand", "model"], name: "index_phone_models_on_brand_and_model", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "branch_number"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "vendedor", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "contracts", "loans"
  add_foreign_key "credit_applications", "customers"
  add_foreign_key "credit_applications", "phone_models", column: "selected_phone_model_id"
  add_foreign_key "credit_applications", "users", column: "vendor_id"
  add_foreign_key "devices", "loans"
  add_foreign_key "devices", "phone_models"
  add_foreign_key "devices", "users", column: "locked_by_id"
  add_foreign_key "installments", "loans"
  add_foreign_key "loans", "customers"
  add_foreign_key "loans", "users"
  add_foreign_key "mdm_blueprints", "devices"
  add_foreign_key "notifications", "customers"
  add_foreign_key "payment_installments", "installments"
  add_foreign_key "payment_installments", "payments"
  add_foreign_key "payments", "loans"
  add_foreign_key "sessions", "users"
end
