class EnhanceNotificationsForPhase5 < ActiveRecord::Migration[7.1]
  def change
    # Add polymorphic recipient support (for Users, Admins, etc.)
    add_column :notifications, :recipient_id, :bigint, if_not_exists: true
    add_column :notifications, :recipient_type, :string, if_not_exists: true

    # Add delivery and status tracking
    add_column :notifications, :delivery_method, :string, if_not_exists: true, default: "fcm"
    add_column :notifications, :status, :string, if_not_exists: true, default: "pending"
    add_column :notifications, :data, :jsonb, if_not_exists: true, default: {}
    add_column :notifications, :error_message, :text, if_not_exists: true

    # Add notification type field if not exists
    unless column_exists?(:notifications, :notification_type)
      add_column :notifications, :notification_type, :string, default: "general"
    end

    # Rename 'body' to 'message' for consistency if it exists
    if column_exists?(:notifications, :body)
      rename_column :notifications, :body, :message
    end

    # Add constraints and indices
    add_index :notifications, [ :recipient_id, :recipient_type, :created_at ], name: "idx_notifications_by_recipient_and_date", if_not_exists: true
    add_index :notifications, [ :status, :sent_at ], name: "idx_notifications_pending_unsent", if_not_exists: true
    add_index :notifications, [ :notification_type, :created_at ], name: "idx_notifications_by_type_and_date", if_not_exists: true
    add_index :notifications, [ :created_at ], name: "idx_notifications_recent", if_not_exists: true
    add_index :notifications, :delivery_method, if_not_exists: true

    # Make customer_id nullable (since we support polymorphic recipients now)
    change_column_null :notifications, :customer_id, true
  end
end
