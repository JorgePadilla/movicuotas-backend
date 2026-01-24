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

ActiveRecord::Schema[8.1].define(version: 2026_01_24_192922) do
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
    t.bigint "loan_id"
    t.text "notes"
    t.string "qr_code_filename"
    t.datetime "qr_code_uploaded_at"
    t.integer "qr_code_uploaded_by_id"
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
    t.integer "otp_attempts", default: 0
    t.string "otp_code"
    t.string "otp_delivery_status", default: "pending"
    t.datetime "otp_sent_at"
    t.datetime "otp_verified_at"
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
    t.index ["otp_delivery_status"], name: "index_credit_applications_on_otp_delivery_status"
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
    t.index ["full_name"], name: "idx_customers_full_name"
    t.index ["identification_number"], name: "index_customers_on_identification_number", unique: true
  end

  create_table "default_qr_codes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "qr_code_filename"
    t.datetime "qr_code_uploaded_at"
    t.integer "qr_code_uploaded_by_id"
    t.datetime "updated_at", null: false
  end

  create_table "device_lock_states", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.bigint "confirmed_by_id"
    t.datetime "created_at", null: false
    t.bigint "device_id", null: false
    t.datetime "initiated_at"
    t.bigint "initiated_by_id"
    t.jsonb "metadata", default: {}
    t.string "reason"
    t.string "status", default: "unlocked", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_device_lock_states_on_confirmed_by_id"
    t.index ["device_id", "created_at"], name: "index_device_lock_states_on_device_id_and_created_at"
    t.index ["device_id"], name: "index_device_lock_states_on_device_id"
    t.index ["initiated_by_id"], name: "index_device_lock_states_on_initiated_by_id"
    t.index ["status"], name: "index_device_lock_states_on_status"
  end

  create_table "device_tokens", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "app_version"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.bigint "device_id"
    t.string "device_name"
    t.datetime "invalidated_at"
    t.datetime "last_used_at"
    t.string "os_version"
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["active"], name: "index_device_tokens_on_active"
    t.index ["customer_id", "active"], name: "idx_device_tokens_by_customer_and_status"
    t.index ["customer_id"], name: "index_device_tokens_on_customer_id"
    t.index ["device_id"], name: "index_device_tokens_on_device_id"
    t.index ["platform", "active"], name: "idx_device_tokens_by_platform_and_status"
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id", "active"], name: "idx_device_tokens_by_user_and_status"
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.datetime "activated_at"
    t.string "activation_code", limit: 8
    t.string "brand", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.string "imei", null: false
    t.bigint "loan_id"
    t.string "model", null: false
    t.text "notes"
    t.bigint "phone_model_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activation_code"], name: "index_devices_on_activation_code", unique: true
    t.index ["imei"], name: "idx_devices_imei"
    t.index ["imei"], name: "index_devices_on_imei", unique: true
    t.index ["loan_id"], name: "idx_devices_loan_id"
    t.index ["loan_id"], name: "index_devices_on_loan_id"
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
    t.index ["loan_id"], name: "idx_installments_loan_id"
    t.index ["loan_id"], name: "index_installments_on_loan_id"
    t.index ["status", "due_date"], name: "idx_installments_status_due_date"
    t.index ["status"], name: "index_installments_on_status"
  end

  create_table "loans", force: :cascade do |t|
    t.decimal "approved_amount", precision: 10, scale: 2, null: false
    t.string "branch_number", null: false
    t.string "contract_number", null: false
    t.datetime "created_at", null: false
    t.bigint "credit_application_id"
    t.bigint "customer_id", null: false
    t.decimal "down_payment_amount", precision: 10, scale: 2, null: false
    t.datetime "down_payment_confirmed_at"
    t.bigint "down_payment_confirmed_by_id"
    t.string "down_payment_method"
    t.decimal "down_payment_percentage", precision: 5, scale: 2, null: false
    t.text "down_payment_rejection_reason"
    t.string "down_payment_verification_status"
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
    t.index ["branch_number"], name: "idx_loans_branch_number"
    t.index ["branch_number"], name: "index_loans_on_branch_number"
    t.index ["contract_number"], name: "index_loans_on_contract_number", unique: true
    t.index ["credit_application_id"], name: "index_loans_on_credit_application_id"
    t.index ["customer_id"], name: "index_loans_on_customer_id"
    t.index ["down_payment_verification_status"], name: "index_loans_on_down_payment_verification_status"
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

  create_table "notification_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "daily_reminders", default: true
    t.boolean "device_blocking_alerts", default: true
    t.string "language", default: "es"
    t.integer "max_notifications_per_day", default: 10
    t.boolean "overdue_warnings", default: true
    t.boolean "payment_confirmations", default: true
    t.boolean "promotional_messages", default: false
    t.time "quiet_hours_end"
    t.time "quiet_hours_start"
    t.boolean "receive_email_notifications", default: true
    t.boolean "receive_fcm_notifications", default: true
    t.boolean "receive_sms_notifications", default: false
    t.string "reminder_frequency", default: "daily"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "idx_notification_preferences_by_user"
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.jsonb "data", default: {}
    t.string "delivery_method", default: "fcm"
    t.text "error_message"
    t.text "message", null: false
    t.text "metadata"
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id"
    t.string "recipient_type"
    t.datetime "sent_at"
    t.string "status", default: "pending"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "idx_notifications_recent"
    t.index ["customer_id"], name: "index_notifications_on_customer_id"
    t.index ["delivery_method"], name: "index_notifications_on_delivery_method"
    t.index ["notification_type", "created_at"], name: "idx_notifications_by_type_and_date"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["recipient_id", "recipient_type", "created_at"], name: "idx_notifications_by_recipient_and_date"
    t.index ["sent_at"], name: "index_notifications_on_sent_at"
    t.index ["status", "sent_at"], name: "idx_notifications_pending_unsent"
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
    t.string "bank_source"
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.text "notes"
    t.datetime "notified_at"
    t.date "payment_date", null: false
    t.string "payment_method", null: false
    t.string "reference_number"
    t.datetime "updated_at", null: false
    t.string "verification_status", default: "pending"
    t.datetime "verified_at"
    t.bigint "verified_by_id"
    t.index ["loan_id"], name: "index_payments_on_loan_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["verification_status"], name: "index_payments_on_verification_status"
    t.index ["verified_by_id"], name: "index_payments_on_verified_by_id"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "updated_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "idx_on_expires_at_concurrency_key_c20fd0827b"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_on_queue_name_and_finished_at"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_on_scheduled_at_and_finished_at"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.datetime "updated_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_ready_executions_on_priority_and_job_id"
    t.index ["queue_name", "priority", "job_id"], name: "idx_on_queue_name_priority_job_id_b116c992cd"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "idx_on_scheduled_at_priority_job_id_cf978ceebd"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
  add_foreign_key "contracts", "users", column: "qr_code_uploaded_by_id"
  add_foreign_key "credit_applications", "customers"
  add_foreign_key "credit_applications", "phone_models", column: "selected_phone_model_id"
  add_foreign_key "credit_applications", "users", column: "vendor_id"
  add_foreign_key "default_qr_codes", "users", column: "qr_code_uploaded_by_id"
  add_foreign_key "device_lock_states", "devices"
  add_foreign_key "device_lock_states", "users", column: "confirmed_by_id"
  add_foreign_key "device_lock_states", "users", column: "initiated_by_id"
  add_foreign_key "device_tokens", "customers"
  add_foreign_key "device_tokens", "devices"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "devices", "loans"
  add_foreign_key "devices", "phone_models"
  add_foreign_key "installments", "loans"
  add_foreign_key "loans", "credit_applications"
  add_foreign_key "loans", "customers"
  add_foreign_key "loans", "users"
  add_foreign_key "loans", "users", column: "down_payment_confirmed_by_id"
  add_foreign_key "mdm_blueprints", "devices"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "customers"
  add_foreign_key "payment_installments", "installments"
  add_foreign_key "payment_installments", "payments"
  add_foreign_key "payments", "loans"
  add_foreign_key "payments", "users", column: "verified_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
