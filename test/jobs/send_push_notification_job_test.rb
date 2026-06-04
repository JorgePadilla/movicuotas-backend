# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class SendPushNotificationJobTest < ActiveJob::TestCase
  setup do
    @customer = customers(:customer_one)
    @notification = Notification.create!(
      customer: @customer,
      title: "T",
      message: "M",
      notification_type: "payment_reminder",
      delivery_method: "fcm"
    )
  end

  # The core regression: one failed send must NOT spawn another notification.
  test "a failed FCM send does not create another notification (no loop)" do
    FcmService.stub(:configured?, true) do
      FcmService.stub(:send_to_customer, aggregate_failure) do
        assert_no_difference("Notification.count") do
          SendPushNotificationJob.perform_now(notification_id: @notification.id)
        end
      end
    end

    assert_equal "failed", @notification.reload.status
  end

  test "failure stores a meaningful error_message instead of a bare colon" do
    FcmService.stub(:configured?, true) do
      FcmService.stub(:send_to_customer, aggregate_failure) do
        SendPushNotificationJob.perform_now(notification_id: @notification.id)
      end
    end

    msg = @notification.reload.error_message
    assert_includes msg, "500"
    assert_includes msg, "FCM request failed"
    refute_equal ":", msg.to_s.strip
  end

  test "does not reprocess an already-failed notification" do
    @notification.update_column(:status, "failed")

    # send_to_customer is intentionally NOT stubbed: if the early return fails to
    # short-circuit, the job would attempt a real send and this test would error.
    FcmService.stub(:configured?, true) do
      assert_no_difference("Notification.count") do
        SendPushNotificationJob.perform_now(notification_id: @notification.id)
      end
    end

    assert_equal "failed", @notification.reload.status
  end

  private

  # Mirrors the shape FcmService.send_to_customer actually returns: an aggregate
  # hash with no top-level :error_code/:error, only per-token :results.
  def aggregate_failure
    {
      success: false,
      total: 1,
      successful: 0,
      failed: 1,
      results: [{ success: false, error_code: "500", error: "FCM request failed" }]
    }
  end
end
