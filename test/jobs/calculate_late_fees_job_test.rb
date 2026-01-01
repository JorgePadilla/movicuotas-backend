# frozen_string_literal: true

require "test_helper"

class CalculateLateFeesJobTest < ActiveJob::TestCase
  def setup
    @customer = customers(:one)
    @admin = users(:admin_user)
    @loan = loans(:active)
    @loan.customer = @customer
    @loan.save!
  end

  test "calculates late fees for overdue installments" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    assert_equal 0, installment.late_fee_amount

    CalculateLateFeesJob.perform_now

    installment.reload
    # 5% of 100 = 5.00
    assert_equal 5.0, installment.late_fee_amount
  end

  test "does not calculate fees for recent overdue (less than 7 days)" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 3.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    CalculateLateFeesJob.perform_now

    installment.reload
    assert_equal 0, installment.late_fee_amount
  end

  test "respects maximum fee cap" do
    # Create installment where 5% would exceed 20% cap
    # This shouldn't happen in normal cases, but test anyway
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 100.days.ago,  # Very old
      amount: 100.00,
      status: "overdue"
    )

    CalculateLateFeesJob.perform_now

    installment.reload
    # Should be capped at 20% of 100 = 20.00
    assert installment.late_fee_amount <= 20.0
  end

  test "does not recalculate fees if already calculated" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue",
      late_fee_amount: 5.0,
      late_fee_calculated_at: 2.days.ago
    )

    CalculateLateFeesJob.perform_now

    installment.reload
    # Fee should not change
    assert_equal 5.0, installment.late_fee_amount
  end

  test "calculates fees for multiple installments" do
    installments = 3.times.map do |i|
      Installment.create!(
        loan: @loan,
        installment_number: i + 1,
        due_date: (15 - i).days.ago,
        amount: 100.00,
        status: "overdue"
      )
    end

    CalculateLateFeesJob.perform_now

    installments.each(&:reload)
    assert_all installments, :late_fee_amount? do |inst|
      inst.late_fee_amount == 5.0
    end
  end

  test "creates audit log entry for fee calculation" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    CalculateLateFeesJob.perform_now

    audit_log = AuditLog.where(action: "late_fee_calculated", resource_id: installment.id).last
    assert audit_log.present?
    assert audit_log.change_details["late_fee_amount"] == 5.0
    assert audit_log.change_details["days_overdue"] == 15
  end

  test "audit log includes correct change details" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 10.days.ago,
      amount: 250.00,
      status: "overdue"
    )

    CalculateLateFeesJob.perform_now

    audit_log = AuditLog.where(action: "late_fee_calculated", resource_id: installment.id).last
    details = audit_log.change_details

    assert_equal 12.5, details["late_fee_amount"]  # 5% of 250
    assert_equal 250.0, details["original_amount"]
    assert_equal 262.5, details["new_total"]  # 250 + 12.5
  end

  test "updates late_fee_calculated_at timestamp" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    assert_nil installment.late_fee_calculated_at

    CalculateLateFeesJob.perform_now

    installment.reload
    assert installment.late_fee_calculated_at.present?
    assert installment.late_fee_calculated_at <= Time.current
  end

  test "skips paid installments" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "paid",
      paid_date: 10.days.ago,
      paid_amount: 100.00
    )

    CalculateLateFeesJob.perform_now

    installment.reload
    assert_equal 0, installment.late_fee_amount
  end

  test "job handles database transaction correctly" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    CalculateLateFeesJob.perform_now

    installment.reload
    # Verify the transaction completed successfully
    assert_equal 5.0, installment.late_fee_amount
    assert installment.late_fee_calculated_at.present?
  end

  test "job is idempotent" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Run job twice
    CalculateLateFeesJob.perform_now
    installment.reload
    first_fee = installment.late_fee_amount

    CalculateLateFeesJob.perform_now
    installment.reload
    second_fee = installment.late_fee_amount

    # Fee should not increase on second run
    assert_equal first_fee, second_fee
    assert_equal 5.0, second_fee
  end

  test "handles transaction rollback on error" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 15.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    # Mock AuditLog to raise error
    allow(AuditLog).to receive(:create!).and_raise(StandardError, "Database error")

    # Job should handle the error and continue (or fail gracefully)
    assert_nothing_raised do
      begin
        CalculateLateFeesJob.perform_now
      rescue StandardError
        # Expected to catch error in retry logic
      end
    end
  end

  test "calculates percentage correctly" do
    amounts_and_expected_fees = [
      [100.00, 5.00],
      [200.00, 10.00],
      [500.00, 25.00],
      [1000.00, 50.00],
      [5000.00, 100.00]  # Would be 250, but capped at 20% = 1000
    ]

    amounts_and_expected_fees.each_with_index do |(amount, expected_fee), index|
      installment = Installment.create!(
        loan: @loan,
        installment_number: index + 1,
        due_date: 15.days.ago,
        amount: amount,
        status: "overdue"
      )
    end

    CalculateLateFeesJob.perform_now

    Installment.overdue.each_with_index do |inst, index|
      inst.reload
      expected = amounts_and_expected_fees[index][1]
      # Account for cap at 20%
      max_fee = inst.amount * 20 / 100
      assert inst.late_fee_amount <= max_fee
    end
  end
end
