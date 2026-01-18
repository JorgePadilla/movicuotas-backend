class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    # Skip if table already exists (created via schema:load in development)
    return if table_exists?(:device_tokens)

    create_table :device_tokens do |t|
      t.string :token, null: false
      t.string :platform, null: false
      t.references :user, null: false, foreign_key: true
      t.string :device_name
      t.string :os_version
      t.string :app_version
      t.datetime :last_used_at
      t.datetime :invalidated_at
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
    add_index :device_tokens, :active
    add_index :device_tokens, [ :user_id, :active ], name: "idx_device_tokens_by_user_and_status"
    add_index :device_tokens, [ :platform, :active ], name: "idx_device_tokens_by_platform_and_status"
  end
end
