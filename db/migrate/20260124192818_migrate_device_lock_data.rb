class MigrateDeviceLockData < ActiveRecord::Migration[8.1]
  def up
    # Migrate existing lock data from devices to device_lock_states
    execute <<~SQL
      INSERT INTO device_lock_states (device_id, status, reason, initiated_by_id, initiated_at, confirmed_at, metadata, created_at, updated_at)
      SELECT
        id,
        COALESCE(lock_status, 'unlocked'),
        'Migrated from legacy data',
        locked_by_id,
        COALESCE(locked_at, created_at),
        locked_at,
        '{}',
        COALESCE(locked_at, created_at),
        NOW()
      FROM devices
      WHERE lock_status IS NOT NULL AND (lock_status != 'unlocked' OR locked_by_id IS NOT NULL)
    SQL
  end

  def down
    execute "DELETE FROM device_lock_states WHERE reason = 'Migrated from legacy data'"
  end
end
