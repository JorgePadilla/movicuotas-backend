# frozen_string_literal: true

class AddLateFeeFieldsForPhase5 < ActiveRecord::Migration[8.1]
  def change
    # Add late fee tracking fields to installments
    add_column :installments, :late_fee_amount, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :installments, :late_fee_calculated_at, :datetime, null: true

    # Add index for finding installments needing late fee calculation
    add_index :installments, [:status, :late_fee_calculated_at], name: "idx_installments_overdue_fee_calculation"

    # Add auto-block notification tracking to devices
    add_column :devices, :auto_block_notified_at, :datetime, null: true

    # Add index for devices eligible for auto-blocking
    add_index :devices, [:lock_status, :auto_block_notified_at], name: "idx_devices_auto_block_tracking"
  end
end
