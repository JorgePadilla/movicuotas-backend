class AddIndicesForOverdueDevicesOptimization < ActiveRecord::Migration[8.1]
  def change
    # Index for overdue installments filtering (status + due_date for sorting)
    add_index :installments, [:status, :due_date], name: :idx_installments_status_due_date

    # Index for installment-to-loan relationships
    add_index :installments, :loan_id, name: :idx_installments_loan_id

    # Index for device-to-loan relationships
    add_index :devices, :loan_id, name: :idx_devices_loan_id

    # Index for branch filtering in overdue devices
    add_index :loans, :branch_number, name: :idx_loans_branch_number

    # Index for IMEI search
    add_index :devices, :imei, name: :idx_devices_imei

    # Index for customer name search (full text would be better for production)
    add_index :customers, :full_name, name: :idx_customers_full_name

    # Index for device lock status and blocking operations
    add_index :devices, [:lock_status, :locked_at], name: :idx_devices_lock_status_locked_at
  end
end
