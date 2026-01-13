# frozen_string_literal: true

class CleanupOldNotificationsJob < ApplicationJob
  queue_as :default
  set_priority :low

  # Keep notifications for 90 days by default
  RETENTION_DAYS = 90

  def perform
    log_execution("Starting: Cleaning up old notifications")

    deleted_count = cleanup_old_notifications
    log_execution("Completed: Deleted #{deleted_count} old notifications", :info, { count: deleted_count })
    track_metric("notifications_cleaned_up", deleted_count)
  rescue StandardError => e
    log_execution("Error cleaning up notifications: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def cleanup_old_notifications
    cutoff_date = RETENTION_DAYS.days.ago

    # Delete read notifications older than retention period
    deleted = Notification.where("read_at IS NOT NULL")
                          .where("created_at < ?", cutoff_date)
                          .delete_all

    log_execution("Deleted #{deleted} read notifications older than #{RETENTION_DAYS} days", :debug)

    # Also delete unread notifications older than 2x retention period (very old)
    very_old_cutoff = (RETENTION_DAYS * 2).days.ago
    very_old_deleted = Notification.where("created_at < ?", very_old_cutoff)
                                   .delete_all

    if very_old_deleted > 0
      log_execution("Deleted #{very_old_deleted} very old notifications (#{RETENTION_DAYS * 2}+ days)", :debug)
    end

    deleted + very_old_deleted
  end
end
