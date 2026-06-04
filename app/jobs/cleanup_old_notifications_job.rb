# frozen_string_literal: true

class CleanupOldNotificationsJob < ApplicationJob
  queue_as :default
  set_priority :low

  # Keep notifications for 90 days by default
  RETENTION_DAYS = 90

  # Failed/undeliverable notifications carry no value after a short window. They
  # are the rows that previously grew unbounded and filled the disk, so purge them
  # aggressively.
  FAILED_RETENTION_DAYS = 7

  # Delete in chunks so we never issue one giant locking/WAL-heavy statement.
  BATCH_SIZE = 10_000

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
    # Purge failed/undeliverable notifications older than the short failed-retention
    # window. This is the class of rows that previously grew without bound.
    failed_deleted = delete_in_batches(
      Notification.where(status: %w[failed failed_permanent skipped])
                  .where("created_at < ?", FAILED_RETENTION_DAYS.days.ago)
    )
    log_execution("Deleted #{failed_deleted} failed notifications older than #{FAILED_RETENTION_DAYS} days", :debug)

    # Delete read notifications older than retention period
    deleted = delete_in_batches(
      Notification.where.not(read_at: nil)
                  .where("created_at < ?", RETENTION_DAYS.days.ago)
    )
    log_execution("Deleted #{deleted} read notifications older than #{RETENTION_DAYS} days", :debug)

    # Also delete any notifications older than 2x retention period (very old)
    very_old_deleted = delete_in_batches(
      Notification.where("created_at < ?", (RETENTION_DAYS * 2).days.ago)
    )
    if very_old_deleted > 0
      log_execution("Deleted #{very_old_deleted} very old notifications (#{RETENTION_DAYS * 2}+ days)", :debug)
    end

    failed_deleted + deleted + very_old_deleted
  end

  # Delete the rows matched by `scope` in bounded chunks. Avoids a single huge
  # DELETE that would lock the table and bloat the WAL (which is what filled the
  # disk in the first place).
  def delete_in_batches(scope, batch_size: BATCH_SIZE)
    total = 0
    loop do
      deleted = Notification.where(id: scope.limit(batch_size).select(:id)).delete_all
      total += deleted
      break if deleted < batch_size
    end
    total
  end
end
