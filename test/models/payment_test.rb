require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @customer = customers(:customer_one)
    @phone_model = phone_models(:iphone_14)

    @loan = Loan.create!(
      customer: @customer,
      user: @user,
      contract_number: "TEST-PAYMENT",
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

    @installment = Installment.create!(
      loan: @loan,
      installment_number: 1,
      due_date: 14.days.from_now,
      amount: 75.00,
      status: "pending"
    )

    @payment = Payment.new(
      installment: @installment,
      amount: 75.00,
      payment_date: Date.today,
      payment_method: "cash",
      status: "pending"
    )
  end

  # Validations - Installment
  test "validates presence of installment" do
    @payment.installment = nil
    assert @payment.invalid?
    assert_includes @payment.errors[:installment], "can't be blank"
  end

  # Validations - Amount
  test "validates presence of amount" do
    @payment.amount = nil
    assert @payment.invalid?
    assert_includes @payment.errors[:amount], "can't be blank"
  end

  test "validates amount is positive" do
    @payment.amount = 0
    assert @payment.invalid?
    assert @payment.errors[:amount].any?
  end

  test "validates amount is greater than zero" do
    @payment.amount = -50.00
    assert @payment.invalid?
  end

  test "accepts positive decimal amounts" do
    @payment.amount = 75.99
    assert @payment.valid?
  end

  # Validations - Payment Date
  test "validates presence of payment_date" do
    @payment.payment_date = nil
    assert @payment.invalid?
    assert_includes @payment.errors[:payment_date], "can't be blank"
  end

  test "validates payment_date is a valid date" do
    @payment.payment_date = "invalid"
    assert @payment.invalid?
  end

  # Validations - Payment Method
  test "validates payment_method inclusion" do
    @payment.payment_method = "crypto"
    assert @payment.invalid?
    assert_includes @payment.errors[:payment_method], "is not included in the list"
  end

  test "accepts valid payment_method values" do
    %w[cash transfer card other].each do |method|
      @payment.payment_method = method
      assert @payment.valid?, "Payment method #{method} should be valid"
    end
  end

  # Validations - Status
  test "validates status inclusion" do
    @payment.status = "invalid_status"
    assert @payment.invalid?
    assert_includes @payment.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    %w[pending verified rejected].each do |status|
      @payment.status = status
      assert @payment.valid?, "Status #{status} should be valid"
    end
  end

  # Status Enum
  test "pending? method works" do
    @payment.status = "pending"
    assert @payment.pending?
    assert !@payment.verified?
  end

  test "verified? method works" do
    @payment.status = "verified"
    assert @payment.verified?
    assert !@payment.pending?
  end

  test "rejected? method works" do
    @payment.status = "rejected"
    assert @payment.rejected?
  end

  # Payment Method Enum
  test "cash? method works" do
    @payment.payment_method = "cash"
    assert @payment.cash?
  end

  test "transfer? method works" do
    @payment.payment_method = "transfer"
    assert @payment.transfer?
  end

  test "card? method works" do
    @payment.payment_method = "card"
    assert @payment.card?
  end

  test "other? method works" do
    @payment.payment_method = "other"
    assert @payment.other?
  end

  # Relationships
  test "belongs to installment" do
    assert_respond_to @payment, :installment
    @payment.save!
    assert_equal @installment, @payment.installment
  end

  test "has many payment_installments" do
    assert_respond_to @payment, :payment_installments
  end

  # Receipt Image
  test "can attach receipt image" do
    @payment.save!
    assert_respond_to @payment, :receipt_image
  end

  # Verification Methods
  test "verify! method updates status to verified" do
    @payment.save!
    @payment.verify!
    assert @payment.verified?
  end

  test "reject! method updates status to rejected" do
    @payment.save!
    @payment.reject!
    assert @payment.rejected?
  end

  # Scopes
  test "pending scope returns only pending payments" do
    @payment.status = "pending"
    @payment.save!

    verified = Payment.create!(
      installment: @installment,
      amount: 50.00,
      payment_date: Date.today,
      payment_method: "transfer",
      status: "verified"
    )

    assert_includes Payment.pending, @payment
    assert_not_includes Payment.pending, verified
  end

  test "verified scope returns only verified payments" do
    verified = Payment.create!(
      installment: @installment,
      amount: 50.00,
      payment_date: Date.today,
      payment_method: "transfer",
      status: "verified"
    )

    pending = Payment.create!(
      installment: Installment.create!(
        loan: @loan,
        installment_number: 2,
        due_date: 28.days.from_now,
        amount: 75.00,
        status: "pending"
      ),
      amount: 75.00,
      payment_date: Date.today,
      payment_method: "cash",
      status: "pending"
    )

    assert_includes Payment.verified, verified
    assert_not_includes Payment.verified, pending
  end

  # Allocation Logic
  test "allocate_to_installments method exists" do
    @payment.save!
    assert_respond_to @payment, :allocate_to_installments
  end

  test "total_allocated returns allocated amount" do
    @payment.save!
    # Initially no allocations
    assert_equal 0, @payment.total_allocated
  end

  test "unallocated_amount returns remaining amount" do
    @payment.save!
    expected = @payment.amount - @payment.total_allocated
    assert_equal expected, @payment.unallocated_amount
  end

  # Persistence
  test "saves valid payment" do
    assert @payment.save
    assert_not_nil @payment.id
  end

  test "updates payment attributes" do
    @payment.save!
    @payment.update(amount: 100.00)
    assert_equal 100.00, @payment.reload.amount
  end

  test "updates payment status" do
    @payment.save!
    @payment.update(status: "verified")
    assert_equal "verified", @payment.reload.status
  end

  # Edge Cases
  test "handles very precise decimal amounts" do
    @payment.amount = 75.999
    assert @payment.valid?
  end

  test "handles very large amounts" do
    @payment.amount = 1_000_000.00
    assert @payment.valid?
  end

  test "payment_date can be in the past" do
    @payment.payment_date = 30.days.ago
    assert @payment.valid?
  end

  test "payment_date can be today" do
    @payment.payment_date = Date.today
    assert @payment.valid?
  end

  test "payment_date can be in the future" do
    @payment.payment_date = 30.days.from_now
    assert @payment.valid?
  end

  # Default Values
  test "status defaults to pending" do
    new_payment = Payment.new(
      installment: @installment,
      amount: 75.00,
      payment_date: Date.today,
      payment_method: "cash"
    )
    assert_equal "pending", new_payment.status
  end

  # Payment Method Variations
  test "accepts cash payment method" do
    @payment.payment_method = "cash"
    assert @payment.valid?
  end

  test "accepts transfer payment method" do
    @payment.payment_method = "transfer"
    assert @payment.valid?
  end

  test "accepts card payment method" do
    @payment.payment_method = "card"
    assert @payment.valid?
  end

  test "accepts other payment method" do
    @payment.payment_method = "other"
    assert @payment.valid?
  end

  # Relationships with Installment
  test "payment belongs to an installment" do
    @payment.save!
    assert @payment.installment.present?
    assert_equal @installment.id, @payment.installment.id
  end

  test "destroying payment does not destroy installment" do
    @payment.save!
    @payment.destroy
    assert @installment.reload.present?
  end

  # Amount Validation with Installment
  test "can pay more than installment amount" do
    @payment.amount = 150.00  # More than installment (75.00)
    assert @payment.valid?  # Should be valid, allocation logic handles it
  end

  test "can pay less than installment amount" do
    @payment.amount = 50.00  # Less than installment (75.00)
    assert @payment.valid?
  end

  # Status Transitions
  test "can transition from pending to verified" do
    @payment.save!
    @payment.verify!
    assert @payment.verified?
  end

  test "can transition from pending to rejected" do
    @payment.save!
    @payment.reject!
    assert @payment.rejected?
  end

  # Audit Trail
  test "payment records creation timestamp" do
    @payment.save!
    assert @payment.created_at.present?
  end

  test "payment records update timestamp" do
    @payment.save!
    original_updated_at = @payment.updated_at

    sleep(0.1)  # Small delay to ensure timestamp difference
    @payment.update(status: "verified")

    assert @payment.updated_at > original_updated_at
  end
end
