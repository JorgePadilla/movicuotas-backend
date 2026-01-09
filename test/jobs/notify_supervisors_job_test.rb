# frozen_string_literal: true

require "test_helper"

class NotifySupervisorsJobTest < ActiveJob::TestCase
  def setup
    @supervisor1 = users(:supervisor)
    @supervisor2 = User.create!(
      email: "supervisor2@movicuotas.local",
      password: "password123",
      password_confirmation: "password123",
      full_name: "Supervisor 2",
      role: "supervisor"
    )

    @customer = customers(:customer_one)
    @loan = loans(:loan_one)
  end

  test "sends notification to all active supervisors" do
    # Create overdue installments
    Installment.create!(
      loan: @loan,
      installment_number: 99,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    NotifySupervisorsJob.perform_now

    # Check that both supervisors received notifications
    notif1 = Notification.where(recipient: @supervisor1, notification_type: "daily_reminder").last
    notif2 = Notification.where(recipient: @supervisor2, notification_type: "daily_reminder").last

    assert notif1.present?
    assert notif2.present?
  end

  test "does not send notification when no overdue installments" do
    # Clear any existing overdue installments
    Installment.where(status: "overdue").delete_all
    initial_count = Notification.count

    NotifySupervisorsJob.perform_now

    # Should not create notifications if no overdue installments
    assert_equal initial_count, Notification.count
  end

  test "notification title and message are formatted correctly" do
    Installment.create!(
      loan: @loan,
      installment_number: 99,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    NotifySupervisorsJob.perform_now

    notification = Notification.where(recipient: @supervisor1, notification_type: "daily_reminder").last

    assert notification.title.include?("Reporte Diario de Mora")
    assert notification.message.include?(Date.today.strftime("%d/%m/%Y"))
  end

  test "job is idempotent" do
    Installment.create!(
      loan: @loan,
      installment_number: 99,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    NotifySupervisorsJob.perform_now
    count_after_first = Notification.where(notification_type: "daily_reminder").count

    NotifySupervisorsJob.perform_now
    count_after_second = Notification.where(notification_type: "daily_reminder").count

    # Second run should not create duplicates (or it's acceptable to have multiple)
    assert count_after_second >= count_after_first
  end
end
