class AddCustomerIdToDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    # Skip if customer_id column already exists (created via schema:load in development)
    return if column_exists?(:device_tokens, :customer_id)

    # Add customer_id (nullable - token can belong to User OR Customer)
    add_reference :device_tokens, :customer, null: true, foreign_key: true

    # Make user_id nullable (was required before)
    change_column_null :device_tokens, :user_id, true

    # Add index for customer lookups
    add_index :device_tokens, [ :customer_id, :active ], name: "idx_device_tokens_by_customer_and_status"
  end
end
