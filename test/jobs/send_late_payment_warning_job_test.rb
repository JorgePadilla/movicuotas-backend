# frozen_string_literal: true

require "test_helper"

class SendLatePaymentWarningJobTest < ActiveJob::TestCase
  def setup
    @customer = customers(:one)
    @user = users(:customer_user)
    @customer.user = @user
    @customer.save!

    @loan = loans(:active)
    @loan.customer = @customer
    @loan.save!
  end

  test "sends warning at 3 days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 3.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "payment_reminder").last
    assert notification.present?
    assert notification.message.include?("próximo a vencer")
  end

  test "sends warning at 7 days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "overdue_warning").last
    assert notification.present?
    assert notification.message.include?("7 días en mora")
  end

  test "sends warning at 14 days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 14.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "overdue_warning").last
    assert notification.present?
    assert notification.message.include?("14 días en mora")
    assert notification.message.include?("bloqueo")
  end

  test "sends critical warning at 27 days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 27.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "device_lock").last
    assert notification.present?
    assert notification.title.include?("CRÍTICO")
    assert notification.message.include?("BLOQUEADO en 3 DÍAS")
  end

  test "warning message includes total overdue amount" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 250.50,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer).last
    assert notification.message.include?("250.50")
  end

  test "respects notification preferences" do
    preference = NotificationPreference.create!(
      user: @user,
      overdue_warnings: false
    )

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_count = Notification.count
    SendLatePaymentWarningJob.perform_now

    # Should not create notification if preference is disabled
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

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_count = Notification.count
    SendLatePaymentWarningJob.perform_now

    assert_equal initial_count, Notification.count
  end

  test "warning data includes correct metadata" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    SendLatePaymentWarningJob.perform_now

    notification = Notification.where(customer: @customer).last
    assert_equal 7, notification.data["days_overdue"]
    assert_equal "warning", notification.data["warning_level"]
    assert_equal 100.0, notification.data["total_amount"]
    assert_equal 7, notification.data["threshold"]
  end

  test "does not send warning on non-threshold days" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_count = Notification.count
    SendLatePaymentWarningJob.perform_now

    # No notification on day 5 (not a threshold)
    assert_equal initial_count, Notification.count
  end

  test "job is idempotent" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 7.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    SendLatePaymentWarningJob.perform_now
    count_after_first = Notification.where(customer: @customer).count

    SendLatePaymentWarningJob.perform_now
    count_after_second = Notification.where(customer: @customer).count

    # Second run should not create duplicate notifications
    assert_equal count_after_first, count_after_second
  end
end
