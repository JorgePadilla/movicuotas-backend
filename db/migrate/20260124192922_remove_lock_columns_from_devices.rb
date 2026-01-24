class RemoveLockColumnsFromDevices < ActiveRecord::Migration[8.1]
  def change
    remove_index :devices, :lock_status
    remove_index :devices, [:lock_status, :locked_at], name: :idx_devices_lock_status_locked_at
    remove_index :devices, :locked_by_id
    remove_column :devices, :lock_status, :string
    remove_column :devices, :locked_at, :datetime
    remove_reference :devices, :locked_by, foreign_key: { to_table: :users }
  end
end
