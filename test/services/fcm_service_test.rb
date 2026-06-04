# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

# Regression coverage for the notification-creation loop.
#
# FcmService must be a PURE TRANSPORT: it sends to FCM and returns a result hash,
# but it must NEVER create a Notification record. Creating one here re-fired
# Notification's after_create_commit callback, which re-enqueued the send, which
# called FcmService again — an unbounded loop that filled the disk and crashed PG.
class FcmServiceTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:customer_one)
    @customer.device_tokens.create!(token: "a" * 60, platform: "android")
  end

  test "send_to_customer creates no Notification on success (pure transport)" do
    FcmService.stub(:configured?, true) do
      FcmService.stub(:send_notification, { success: true, message_id: "x" }) do
        assert_no_difference("Notification.count") do
          result = FcmService.send_to_customer(@customer, title: "t", body: "b")
          assert result[:success]
        end
      end
    end
  end

  test "send_to_customer creates no Notification on failure (pure transport)" do
    FcmService.stub(:configured?, true) do
      FcmService.stub(:send_notification, { success: false, error_code: "500", error: "FCM request failed" }) do
        assert_no_difference("Notification.count") do
          result = FcmService.send_to_customer(@customer, title: "t", body: "b")
          assert_not result[:success]
        end
      end
    end
  end

  test "send_to_customer returns early for a customer with no active device tokens" do
    tokenless = customers(:customer_two)
    FcmService.stub(:configured?, true) do
      assert_no_difference("Notification.count") do
        result = FcmService.send_to_customer(tokenless, title: "t", body: "b")
        assert_not result[:success]
        assert_equal "No active device tokens", result[:error]
      end
    end
  end
end
