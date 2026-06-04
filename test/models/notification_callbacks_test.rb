# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

# Verifies the enqueue invariant: only a brand-new PENDING fcm notification may
# enqueue a push send. A terminal-status row (delivered/failed/failed_permanent/
# skipped) must never re-enqueue — that was a path back into the send loop.
#
# We stub SendPushNotificationJob.perform_later directly so the assertion does
# not depend on the configured ActiveJob adapter or transaction-commit timing.
class NotificationCallbacksTest < ActiveSupport::TestCase
  setup { @customer = customers(:customer_one) }

  test "enqueues a push send for a pending fcm notification" do
    assert_equal 1, enqueues_from_queue_push("pending")
  end

  test "never enqueues for terminal statuses" do
    %w[delivered failed failed_permanent skipped].each do |terminal|
      assert_equal 0, enqueues_from_queue_push(terminal),
                   "status #{terminal} must not enqueue a push send"
    end
  end

  private

  # Returns how many times queue_push_notification enqueues a send for a
  # notification in the given status. perform_later is stubbed for the whole
  # block; the counter is reset after creation so we measure ONLY the explicit
  # queue_push_notification call (not the create-time after_create_commit).
  def enqueues_from_queue_push(status)
    calls = []
    SendPushNotificationJob.stub(:perform_later, ->(**kwargs) { calls << kwargs }) do
      notification = Notification.create!(
        customer: @customer, title: "T", message: "M",
        notification_type: "general", delivery_method: "fcm"
      )
      notification.update_column(:status, status)
      calls.clear
      notification.send(:queue_push_notification)
    end
    calls.size
  end
end
