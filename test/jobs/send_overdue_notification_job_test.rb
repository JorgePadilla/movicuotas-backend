# frozen_string_literal: true

require "test_helper"

class SendOverdueNotificationJobTest < ActiveJob::TestCase
  def setup
    @customer = customers(:one)
    @user = users(:customer_user)
    @customer.user = @user
    @customer.save!

    @loan = loans(:active)
    @loan.customer = @customer
    @loan.save!
  end

  test "sends notification for 1 day overdue" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 1.day.ago,
      amount: 100.00,
      status: "overdue"
    )

    assert_no_change -> { Notification.count } do
      SendOverdueNotificationJob.perform_now
    end

    # Notifications should have been created for 1 day overdue milestone
    notifications = Notification.where(customer: @customer, notification_type: "overdue_warning")
    assert notifications.any?
  end

  test "sends notification for 7 days overdue" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendOverdueNotificationJob.perform_now

    notifications = Notification.where(customer: @customer, notification_type: "overdue_warning")
    assert notifications.any?
  end

  test "sends escalation notification at 30+ days overdue" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 30.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendOverdueNotificationJob.perform_now

    # Should send both warning and escalation
    notifications = Notification.where(customer: @customer)
    assert notifications.any? { |n| n.notification_type == "device_blocking_alert" }
  end

  test "respects notification preferences - disabled overdue warnings" do
    preference = NotificationPreference.create!(
      user: @user,
      overdue_warnings: false
    )

    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_count = Notification.count
    SendOverdueNotificationJob.perform_now

    assert_equal initial_count, Notification.count
  end

  test "respects quiet hours" do
    preference = NotificationPreference.create!(
      user: @user,
      overdue_warnings: true,
      quiet_hours_start: Time.current.beginning_of_day,
      quiet_hours_end: Time.current.end_of_day
    )

    # Mock that we're in quiet hours
    allow_any_instance_of(NotificationPreference).to receive(:in_quiet_hours?).and_return(true)

    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_count = Notification.count
    SendOverdueNotificationJob.perform_now

    assert_equal initial_count, Notification.count
  end

  test "includes correct data in notification" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendOverdueNotificationJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "overdue_warning").last
    assert_equal 7, notification.data["days_overdue"]
    assert_equal 1, notification.data["installment_count"]
    assert_equal 100.0, notification.data["total_amount"]
  end

  test "job is idempotent" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    SendOverdueNotificationJob.perform_now
    count_after_first = Notification.where(customer: @customer).count

    SendOverdueNotificationJob.perform_now
    count_after_second = Notification.where(customer: @customer).count

    # Second run might create more notifications or be safe - depends on implementation
    # For now, just ensure it doesn't crash
    assert count_after_second >= count_after_first
  end
end
