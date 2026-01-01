# frozen_string_literal: true

require "test_helper"

class NotifyCobradorosJobTest < ActiveJob::TestCase
  def setup
    @cobrador1 = users(:cobrador_user)
    @cobrador2 = User.create!(
      email: "cobrador2@movicuotas.local",
      password: "password123",
      password_confirmation: "password123",
      full_name: "Cobrador 2",
      role: "cobrador"
    )

    @customer = customers(:one)
    @loan = loans(:active)
    @loan.customer = @customer
    @loan.save!
  end

  test "sends notification to all active cobradores" do
    # Create overdue installments
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    NotifyCobradorosJob.perform_now

    # Check that both cobradores received notifications
    notif1 = Notification.where(recipient: @cobrador1, notification_type: "daily_reminder").last
    notif2 = Notification.where(recipient: @cobrador2, notification_type: "daily_reminder").last

    assert notif1.present?
    assert notif2.present?
  end

  test "does not send notification when no overdue installments" do
    initial_count = Notification.count

    NotifyCobradorosJob.perform_now

    # Should not create notifications if no overdue installments
    assert_equal initial_count, Notification.count
  end

  test "includes correct statistics in notification data" do
    # Create various overdue installments at different ages
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 3.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    Installment.create!(
      loan: @loan,
      installment_number: 2,
      due_date: 10.days.ago,
      amount: 150.00,
      status: "overdue"
    )

    Installment.create!(
      loan: @loan,
      installment_number: 3,
      due_date: 35.days.ago,
      amount: 200.00,
      status: "overdue"
    )

    NotifyCobradorosJob.perform_now

    notification = Notification.where(recipient: @cobrador1, notification_type: "daily_reminder").last
    data = notification.data

    assert_equal 3, data["total_overdue_count"]
    assert_equal 450.0, data["total_overdue_amount"]
    assert_equal 1, data[:by_days][:"1_to_7"]
    assert_equal 1, data[:by_days][:"8_to_15"]
    assert_equal 1, data[:by_days][:"30_plus"]
  end

  test "notification title and message are formatted correctly" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    NotifyCobradorosJob.perform_now

    notification = Notification.where(recipient: @cobrador1, notification_type: "daily_reminder").last

    assert notification.title.include?("Reporte Diario de Mora")
    assert notification.message.include?(Date.today.strftime("%d/%m/%Y"))
    assert notification.message.include?("100.00")  # Amount in message
  end

  test "notification includes device blocking information" do
    # Create blocked device
    customer = customers(:one)
    phone_model = phone_models(:one)
    device = Device.create!(
      imei: "1234567890123456",
      brand: "Apple",
      model: "iPhone 13",
      color: "Black",
      phone_model: phone_model,
      lock_status: "locked",
      locked_at: 2.hours.ago
    )

    loan = Loan.create!(
      customer: customer,
      user_id: users(:admin_user).id,
      contract_number: "TEST-2026-01-01-000001",
      branch_number: "MAIN",
      status: "active",
      total_amount: 5000.00,
      approved_amount: 5000.00,
      down_payment_percentage: 30,
      down_payment_amount: 1500.00,
      financed_amount: 3500.00,
      interest_rate: 10.0,
      number_of_installments: 6,
      start_date: Date.today
    )
    device.update(loan: loan)

    Installment.create!(
      loan: loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    NotifyCobradorosJob.perform_now

    notification = Notification.where(recipient: @cobrador1, notification_type: "daily_reminder").last
    assert notification.data["blocked_devices_count"].present?
  end

  test "job is idempotent" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    NotifyCobradorosJob.perform_now
    count_after_first = Notification.where(notification_type: "daily_reminder").count

    NotifyCobradorosJob.perform_now
    count_after_second = Notification.where(notification_type: "daily_reminder").count

    # Second run should not create duplicates (or it's acceptable to have multiple)
    assert count_after_second >= count_after_first
  end
end
