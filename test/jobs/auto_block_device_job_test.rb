# frozen_string_literal: true

require "test_helper"

class AutoBlockDeviceJobTest < ActiveJob::TestCase
  def setup
    @customer = customers(:one)
    @admin = users(:admin_user)
    @phone_model = phone_models(:one)

    @loan = Loan.create!(
      customer: @customer,
      user: @admin,
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

    @device = Device.create!(
      imei: "1234567890123456",
      brand: "Apple",
      model: "iPhone 13",
      color: "Black",
      phone_model: @phone_model,
      loan: @loan,
      lock_status: "unlocked"
    )
  end

  test "blocks devices with 30+ days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    assert_equal "unlocked", @device.lock_status

    AutoBlockDeviceJob.perform_now

    @device.reload
    assert_equal "pending", @device.lock_status
  end

  test "does not block devices with less than 30 days overdue" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 20.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    assert_equal "unlocked", @device.lock_status

    AutoBlockDeviceJob.perform_now

    @device.reload
    assert_equal "unlocked", @device.lock_status
  end

  test "does not block already locked devices" do
    @device.update(lock_status: "locked")

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    AutoBlockDeviceJob.perform_now

    @device.reload
    assert_equal "locked", @device.lock_status
  end

  test "does not block pending block devices" do
    @device.update(lock_status: "pending")

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    initial_status = @device.lock_status

    AutoBlockDeviceJob.perform_now

    @device.reload
    assert_equal initial_status, @device.lock_status
  end

  test "sends device blocking notification to customer" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    AutoBlockDeviceJob.perform_now

    notification = Notification.where(customer: @customer, notification_type: "device_blocking_alert").last
    assert notification.present?
    assert notification.message.include?("bloqueado")
  end

  test "creates audit log entry for device block" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    AutoBlockDeviceJob.perform_now

    @device.reload
    audit_log = AuditLog.where(resource_type: "Device", resource_id: @device.id).last
    assert audit_log.present?
    assert_equal "device_block_requested", audit_log.action
  end

  test "handles multiple devices" do
    # Create second device
    device2 = Device.create!(
      imei: "9876543210987654",
      brand: "Samsung",
      model: "Galaxy S21",
      color: "Gray",
      phone_model: @phone_model,
      loan: @loan,
      lock_status: "unlocked"
    )

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    AutoBlockDeviceJob.perform_now

    @device.reload
    device2.reload

    assert_equal "pending", @device.lock_status
    assert_equal "pending", device2.lock_status
  end

  test "job is idempotent" do
    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    AutoBlockDeviceJob.perform_now
    @device.reload
    first_status = @device.lock_status

    AutoBlockDeviceJob.perform_now
    @device.reload
    second_status = @device.lock_status

    assert_equal first_status, second_status
    assert_equal "pending", second_status
  end

  test "continues processing if one device fails" do
    # Create two devices
    device2 = Device.create!(
      imei: "9876543210987654",
      brand: "Samsung",
      model: "Galaxy S21",
      color: "Gray",
      phone_model: @phone_model,
      loan: @loan,
      lock_status: "unlocked"
    )

    Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 35.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Mock MdmBlockService to fail for first device
    call_count = 0
    allow_any_instance_of(MdmBlockService).to receive(:block!) do
      call_count += 1
      if call_count == 1
        { error: "Service unavailable" }
      else
        { success: true, message: "Blocked" }
      end
    end

    # Job should handle error and continue
    assert_nothing_raised do
      AutoBlockDeviceJob.perform_now
    end

    device2.reload
    # Second device should still be processed
    assert device2.locked? || device2.pending_lock?
  end
end
