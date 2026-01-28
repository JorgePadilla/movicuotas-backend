# frozen_string_literal: true

class ConvertPendingDevicesToLocked < ActiveRecord::Migration[8.0]
  def up
    # Update all "pending" device lock states to "locked"
    execute <<-SQL
      UPDATE device_lock_states
      SET status = 'locked', confirmed_at = COALESCE(confirmed_at, initiated_at, NOW())
      WHERE status = 'pending'
    SQL

    # Log how many records were updated
    count = execute("SELECT COUNT(*) FROM device_lock_states WHERE status = 'pending'").first
    puts "Converted #{count} pending device lock states to locked" if count
  end

  def down
    # This migration is not reversible - we don't know which devices were previously pending
    raise ActiveRecord::IrreversibleMigration
  end
end
