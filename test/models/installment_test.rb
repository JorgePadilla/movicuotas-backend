require "test_helper"

class InstallmentTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @customer = customers(:customer_one)
    @phone_model = phone_models(:iphone_14)

    @loan = Loan.create!(
      customer: @customer,
      user: @user,
      contract_number: "TEST-INSTALL",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    )

    @installment = Installment.new(
      loan: @loan,
      installment_number: 1,
      due_date: 14.days.from_now,
      amount: 75.00,
      status: "pending"
    )
  end

  # Validations - Loan
  test "validates presence of loan" do
    @installment.loan = nil
    assert @installment.invalid?
    assert_includes @installment.errors[:loan], "can't be blank"
  end

  # Validations - Installment Number
  test "validates presence of installment_number" do
    @installment.installment_number = nil
    assert @installment.invalid?
    assert_includes @installment.errors[:installment_number], "can't be blank"
  end

  test "validates installment_number is positive" do
    @installment.installment_number = 0
    assert @installment.invalid?
    assert @installment.errors[:installment_number].any?
  end

  test "validates installment_number uniqueness within loan" do
    @installment.save!

    duplicate = Installment.new(
      loan: @loan,
      installment_number: 1,
      due_date: 28.days.from_now,
      amount: 75.00,
      status: "pending"
    )
    assert duplicate.invalid?
  end

  # Validations - Due Date
  test "validates presence of due_date" do
    @installment.due_date = nil
    assert @installment.invalid?
    assert_includes @installment.errors[:due_date], "can't be blank"
  end

  test "validates due_date is a valid date" do
    @installment.due_date = "invalid-date"
    assert @installment.invalid?
  end

  # Validations - Amount
  test "validates presence of amount" do
    @installment.amount = nil
    assert @installment.invalid?
    assert_includes @installment.errors[:amount], "can't be blank"
  end

  test "validates amount is positive" do
    @installment.amount = 0
    assert @installment.invalid?
    assert @installment.errors[:amount].any?
  end

  test "validates amount is positive decimal" do
    @installment.amount = -50.00
    assert @installment.invalid?
  end

  # Validations - Status
  test "validates status inclusion" do
    @installment.status = "invalid_status"
    assert @installment.invalid?
    assert_includes @installment.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    %w[pending paid overdue cancelled].each do |status|
      @installment.status = status
      assert @installment.valid?, "Status #{status} should be valid"
    end
  end

  # Status Enum
  test "pending? method works" do
    @installment.status = "pending"
    assert @installment.pending?
    assert !@installment.paid?
  end

  test "paid? method works" do
    @installment.status = "paid"
    assert @installment.paid?
    assert !@installment.pending?
  end

  test "overdue? method works" do
    @installment.status = "overdue"
    assert @installment.overdue?
  end

  test "cancelled? method works" do
    @installment.status = "cancelled"
    assert @installment.cancelled?
  end

  # Overdue Calculation
  test "overdue? returns false for future due dates" do
    @installment.due_date = 5.days.from_now
    @installment.status = "pending"
    assert !@installment.overdue?
  end

  test "overdue? returns false for today's due date when paid" do
    @installment.due_date = Date.today
    @installment.status = "paid"
    assert !@installment.overdue?
  end

  test "overdue? returns true for past due dates in pending status" do
    @installment.due_date = 5.days.ago
    @installment.status = "pending"
    assert @installment.overdue?
  end

  # Days Overdue Calculation
  test "days_overdue returns 0 for future due dates" do
    @installment.due_date = 5.days.from_now
    assert_equal 0, @installment.days_overdue
  end

  test "days_overdue returns 0 for paid installments" do
    @installment.due_date = 10.days.ago
    @installment.status = "paid"
    assert_equal 0, @installment.days_overdue
  end

  test "days_overdue returns correct count for overdue pending installments" do
    @installment.due_date = 10.days.ago
    @installment.status = "pending"
    expected_days = (Date.today - @installment.due_date).to_i
    assert_equal expected_days, @installment.days_overdue
  end

  # Paid Amount
  test "remaining_amount returns full amount when nothing paid" do
    @installment.save!
    # Assuming no payments allocated
    assert_equal @installment.amount, @installment.remaining_amount
  end

  test "fully_paid? returns false for pending installment" do
    @installment.status = "pending"
    assert !@installment.fully_paid?
  end

  test "fully_paid? returns true for paid installment" do
    @installment.status = "paid"
    assert @installment.fully_paid?
  end

  # Relationships
  test "belongs to loan" do
    assert_respond_to @installment, :loan
    @installment.save!
    assert_equal @loan, @installment.loan
  end

  test "has many payment_installments" do
    assert_respond_to @installment, :payment_installments
  end

  # Scopes
  test "pending scope returns only pending installments" do
    @installment.status = "pending"
    @installment.save!

    paid = Installment.create!(
      loan: @loan,
      installment_number: 2,
      due_date: 28.days.from_now,
      amount: 75.00,
      status: "paid"
    )

    assert_includes Installment.pending, @installment
    assert_not_includes Installment.pending, paid
  end

  test "paid scope returns only paid installments" do
    paid = Installment.create!(
      loan: @loan,
      installment_number: 2,
      due_date: 28.days.from_now,
      amount: 75.00,
      status: "paid"
    )

    pending = Installment.create!(
      loan: @loan,
      installment_number: 3,
      due_date: 42.days.from_now,
      amount: 75.00,
      status: "pending"
    )

    assert_includes Installment.paid, paid
    assert_not_includes Installment.paid, pending
  end

  test "overdue scope returns only overdue pending installments" do
    overdue = Installment.create!(
      loan: @loan,
      installment_number: 2,
      due_date: 10.days.ago,
      amount: 75.00,
      status: "pending"
    )

    future = Installment.create!(
      loan: @loan,
      installment_number: 3,
      due_date: 10.days.from_now,
      amount: 75.00,
      status: "pending"
    )

    assert_includes Installment.overdue, overdue
    assert_not_includes Installment.overdue, future
  end

  # Persistence
  test "saves valid installment" do
    assert @installment.save
    assert_not_nil @installment.id
  end

  test "updates installment attributes" do
    @installment.save!
    @installment.update(amount: 100.00)
    assert_equal 100.00, @installment.reload.amount
  end

  # Mark as Paid
  test "mark_as_paid! updates status and sets paid_date" do
    @installment.save!
    @installment.mark_as_paid!
    @installment.reload

    assert @installment.paid?
    assert @installment.paid_date.present?
  end

  # Edge Cases
  test "handles very precise decimal amounts" do
    @installment.amount = 75.999
    assert @installment.valid?
  end

  test "installment_number can be very large" do
    @installment.installment_number = 1000
    assert @installment.valid?
  end

  test "due_date can be far in future" do
    @installment.due_date = 10.years.from_now
    assert @installment.valid?
  end

  # Status Transitions
  test "can transition from pending to paid" do
    @installment.save!
    @installment.update(status: "paid")
    assert @installment.paid?
  end

  test "can transition from pending to overdue" do
    @installment.save!
    @installment.update(status: "overdue")
    assert @installment.overdue?
  end

  test "can transition from pending to cancelled" do
    @installment.save!
    @installment.update(status: "cancelled")
    assert @installment.cancelled?
  end

  # Default Values
  test "status defaults to pending" do
    new_installment = Installment.new(
      loan: @loan,
      installment_number: 10,
      due_date: 100.days.from_now,
      amount: 75.00
    )
    assert_equal "pending", new_installment.status
  end

  # Bi-weekly Payment Tracking
  test "correctly calculates bi-weekly due dates" do
    start_date = Date.today
    installment1 = Installment.new(
      loan: @loan,
      installment_number: 1,
      due_date: start_date + 14.days,
      amount: 75.00
    )

    installment2 = Installment.new(
      loan: @loan,
      installment_number: 2,
      due_date: start_date + 28.days,
      amount: 75.00
    )

    expected_diff = (installment2.due_date - installment1.due_date).to_i
    assert_equal 14, expected_diff
  end
end
