# frozen_string_literal: true

require "test_helper"

class PaymentReminderNotificationJobTest < ActiveJob::TestCase
  setup do
    # customer_one gets an active device token; customer_two gets none.
    @with_token = customers(:customer_one)
    @with_token.device_tokens.create!(token: "a" * 60, platform: "android")
    @inst_with = Installment.create!(
      loan: loans(:loan_one), installment_number: 99,
      due_date: Date.today, amount: 500, status: "pending"
    )

    @inst_without = Installment.create!(
      loan: loans(:loan_two), installment_number: 99,
      due_date: Date.today, amount: 500, status: "pending"
    )
  end

  test "creates a reminder for a customer with an active device token" do
    assert_difference -> { reminders_for(@inst_with) }, 1 do
      PaymentReminderNotificationJob.perform_now
    end
  end

  test "skips customers without an active device token" do
    PaymentReminderNotificationJob.perform_now
    assert_equal 0, reminders_for(@inst_without)
  end

  test "is idempotent within the same day" do
    PaymentReminderNotificationJob.perform_now
    assert_no_difference -> { reminders_for(@inst_with) } do
      PaymentReminderNotificationJob.perform_now
    end
  end

  private

  # metadata is JSON-serialized TEXT, e.g. ...,"installment_id":123,...
  def reminders_for(installment)
    Notification.where(notification_type: "payment_reminder")
                .where("metadata LIKE ?", "%\"installment_id\":#{installment.id}%")
                .count
  end
end
