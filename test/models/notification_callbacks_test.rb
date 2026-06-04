# frozen_string_literal: true

require "test_helper"

# Verifies the enqueue invariant: only a brand-new PENDING fcm notification may
# enqueue a push send. A terminal-status row (delivered/failed/failed_permanent/
# skipped) must never re-enqueue — that was a path back into the send loop.
class NotificationCallbacksTest < ActiveJob::TestCase
  setup { @customer = customers(:customer_one) }

  test "enqueues a push send for a pending fcm notification" do
    notification = build_notification(status: "pending")
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      notification.send(:queue_push_notification)
    end
  end

  test "never enqueues for terminal statuses" do
    %w[delivered failed failed_permanent skipped].each do |terminal|
      notification = build_notification(status: terminal)
      assert_no_enqueued_jobs only: SendPushNotificationJob do
        notification.send(:queue_push_notification)
      end
    end
  end

  private

  def build_notification(status:)
    n = Notification.create!(
      customer: @customer, title: "T", message: "M",
      notification_type: "general", delivery_method: "fcm"
    )
    n.update_column(:status, status)
    n
  end
end
