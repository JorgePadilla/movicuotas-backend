# frozen_string_literal: true

require "test_helper"

class MarkInstallmentsOverdueJobTest < ActiveJob::TestCase
  def setup
    @customer = customers(:one)
    @loan = loans(:active)
    @loan.customer = @customer
    @loan.save!
  end

  test "marks pending installments with past due dates as overdue" do
    # Create pending installment with past due date
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "pending"
    )

    assert_equal "pending", installment.status

    MarkInstallmentsOverdueJob.perform_now

    installment.reload
    assert_equal "overdue", installment.status
  end

  test "does not mark pending installments with future due dates" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.from_now,
      amount: 100.00,
      status: "pending"
    )

    assert_equal "pending", installment.status

    MarkInstallmentsOverdueJob.perform_now

    installment.reload
    assert_equal "pending", installment.status
  end

  test "does not affect already overdue installments" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 10.days.ago,
      amount: 100.00,
      status: "overdue"
    )

    MarkInstallmentsOverdueJob.perform_now

    installment.reload
    assert_equal "overdue", installment.status
  end

  test "does not affect paid installments" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "paid",
      paid_date: 3.days.ago,
      paid_amount: 100.00
    )

    MarkInstallmentsOverdueJob.perform_now

    installment.reload
    assert_equal "paid", installment.status
  end

  test "marks multiple overdue installments" do
    installments = 3.times.map do |i|
      Installment.create!(
        loan: @loan,
        installment_number: i + 1,
        due_date: (5 - i).days.ago,
        amount: 100.00,
        status: "pending"
      )
    end

    assert_all_equal "pending", installments.map(&:status)

    MarkInstallmentsOverdueJob.perform_now

    installments.each(&:reload)
    assert_all_equal "overdue", installments.map(&:status)
  end

  test "job is idempotent" do
    installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 5.days.ago,
      amount: 100.00,
      status: "pending"
    )

    # Run job twice
    MarkInstallmentsOverdueJob.perform_now
    installment.reload
    assert_equal "overdue", installment.status

    MarkInstallmentsOverdueJob.perform_now
    installment.reload
    assert_equal "overdue", installment.status
  end
end
