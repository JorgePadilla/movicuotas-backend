class CreateDeviceLockStates < ActiveRecord::Migration[8.1]
  def change
    create_table :device_lock_states do |t|
      t.references :device, null: false, foreign_key: true
      t.string :status, null: false, default: "unlocked"
      t.string :reason
      t.references :initiated_by, foreign_key: { to_table: :users }
      t.references :confirmed_by, foreign_key: { to_table: :users }
      t.datetime :initiated_at
      t.datetime :confirmed_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :device_lock_states, [:device_id, :created_at]
    add_index :device_lock_states, :status
  end
end
