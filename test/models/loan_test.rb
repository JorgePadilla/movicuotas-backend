require "test_helper"

class LoanTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @customer = customers(:customer_one)
    @phone_model = phone_models(:iphone_14)

    @loan = Loan.new(
      customer: @customer,
      user: @user,
      contract_number: "TEST-001",
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
  end

  # Validations - Contract Number
  test "validates presence of contract_number" do
    @loan.contract_number = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:contract_number], "can't be blank"
  end

  test "validates uniqueness of contract_number" do
    @loan.save!
    duplicate = Loan.new(
      customer: @customer,
      user: @user,
      contract_number: @loan.contract_number,
      total_amount: 500.00,
      approved_amount: 500.00,
      down_payment_percentage: 30,
      down_payment_amount: 150.00,
      financed_amount: 350.00,
      interest_rate: 12.5,
      number_of_installments: 6,
      start_date: Date.today,
      end_date: 6.months.from_now,
      branch_number: "BR01",
      status: "draft"
    )
    assert duplicate.invalid?
    assert_includes duplicate.errors[:contract_number], "has already been taken"
  end

  # Validations - Customer & User
  test "validates presence of customer" do
    @loan.customer = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:customer], "can't be blank"
  end

  test "validates presence of user" do
    @loan.user = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:user], "can't be blank"
  end

  # Validations - Branch Number
  test "validates presence of branch_number" do
    @loan.branch_number = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:branch_number], "can't be blank"
  end

  test "validates branch_number format" do
    @loan.branch_number = "invalid"
    assert @loan.invalid?
    assert @loan.errors[:branch_number].any?
  end

  # Validations - Status
  test "validates status inclusion" do
    @loan.status = "unknown"
    assert @loan.invalid?
    assert_includes @loan.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    %w[draft active paid overdue cancelled].each do |status|
      @loan.status = status
      assert @loan.valid?, "Status #{status} should be valid"
    end
  end

  # Validations - Amounts
  test "validates presence of total_amount" do
    @loan.total_amount = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:total_amount], "can't be blank"
  end

  test "validates total_amount is positive" do
    @loan.total_amount = 0
    assert @loan.invalid?
    assert @loan.errors[:total_amount].any?
  end

  test "validates approved_amount >= total_amount" do
    @loan.approved_amount = 500
    @loan.total_amount = 1000
    assert @loan.invalid?
    assert @loan.errors[:approved_amount].any?
  end

  # Validations - Down Payment
  test "validates down_payment_percentage inclusion (30, 40, 50 only)" do
    @loan.down_payment_percentage = 35
    assert @loan.invalid?
    assert_includes @loan.errors[:down_payment_percentage], "is not included in the list"
  end

  test "accepts valid down_payment_percentages" do
    [30, 40, 50].each do |percentage|
      @loan.down_payment_percentage = percentage
      @loan.down_payment_amount = @loan.total_amount * percentage / 100
      @loan.financed_amount = @loan.total_amount - @loan.down_payment_amount
      assert @loan.valid?, "Down payment #{percentage}% should be valid"
    end
  end

  # Validations - Installments
  test "validates number_of_installments inclusion (6, 8, 10, 12 only)" do
    @loan.number_of_installments = 7
    assert @loan.invalid?
    assert_includes @loan.errors[:number_of_installments], "is not included in the list"
  end

  test "accepts valid number_of_installments" do
    [6, 8, 10, 12].each do |terms|
      @loan.number_of_installments = terms
      assert @loan.valid?, "#{terms} installments should be valid"
    end
  end

  # Validations - Interest Rate
  test "validates interest_rate is positive" do
    @loan.interest_rate = -5
    assert @loan.invalid?
    assert @loan.errors[:interest_rate].any?
  end

  test "validates interest_rate <= 100" do
    @loan.interest_rate = 150
    assert @loan.invalid?
    assert @loan.errors[:interest_rate].any?
  end

  # Validations - Dates
  test "validates presence of start_date" do
    @loan.start_date = nil
    assert @loan.invalid?
    assert_includes @loan.errors[:start_date], "can't be blank"
  end

  test "validates start_date is not in the past" do
    @loan.start_date = 1.day.ago
    assert @loan.invalid?
    assert @loan.errors[:start_date].any?
  end

  test "allows start_date to be today or future" do
    @loan.start_date = Date.today
    assert @loan.valid?

    @loan.start_date = 1.day.from_now
    assert @loan.valid?
  end

  # Status Enum
  test "draft? method works" do
    @loan.status = "draft"
    assert @loan.draft?
    assert !@loan.active?
  end

  test "active? method works" do
    @loan.status = "active"
    assert @loan.active?
    assert !@loan.draft?
  end

  test "paid? method works" do
    @loan.status = "paid"
    assert @loan.paid?
  end

  test "overdue? method works" do
    @loan.status = "overdue"
    assert @loan.overdue?
  end

  test "cancelled? method works" do
    @loan.status = "cancelled"
    assert @loan.cancelled?
  end

  # Relationships
  test "belongs to customer" do
    assert_respond_to @loan, :customer
    @loan.save!
    assert_equal @customer, @loan.customer
  end

  test "belongs to user" do
    assert_respond_to @loan, :user
    @loan.save!
    assert_equal @user, @loan.user
  end

  test "has one device" do
    assert_respond_to @loan, :device
  end

  test "has many installments" do
    assert_respond_to @loan, :installments
  end

  test "has many payments" do
    assert_respond_to @loan, :payments
  end

  test "has one contract" do
    assert_respond_to @loan, :contract
  end

  # Scopes
  test "active scope returns only active loans" do
    @loan.status = "active"
    @loan.save!

    inactive = Loan.create!(
      customer: @customer,
      user: @user,
      contract_number: "TEST-INACTIVE",
      total_amount: 500,
      approved_amount: 500,
      down_payment_percentage: 30,
      down_payment_amount: 150,
      financed_amount: 350,
      interest_rate: 12.5,
      number_of_installments: 6,
      start_date: Date.today,
      end_date: 6.months.from_now,
      branch_number: "BR01",
      status: "draft"
    )

    assert_includes Loan.active, @loan
    assert_not_includes Loan.active, inactive
  end

  # Persistence
  test "saves valid loan" do
    assert @loan.save
    assert_not_nil @loan.id
  end

  test "updates loan attributes" do
    @loan.save!
    @loan.update(interest_rate: 15.0)
    assert_equal 15.0, @loan.reload.interest_rate
  end

  # Calculations
  test "calculates financed_amount correctly" do
    @loan.total_amount = 1000
    @loan.down_payment_percentage = 30
    @loan.down_payment_amount = 300
    expected_financed = 1000 - 300
    assert_equal expected_financed, @loan.financed_amount
  end

  test "calculates down_payment_amount correctly" do
    @loan.total_amount = 1000
    @loan.down_payment_percentage = 30
    expected_down_payment = 1000 * 0.30
    assert_equal expected_down_payment, @loan.down_payment_amount
  end

  # Edge Cases
  test "handles very long contract_number" do
    @loan.contract_number = "A" * 100
    assert @loan.valid?
  end

  test "handles decimal amounts precisely" do
    @loan.total_amount = 999.99
    @loan.down_payment_amount = 299.997
    @loan.financed_amount = 700.00
    assert @loan.valid?
  end

  test "loan with minimum down payment" do
    @loan.down_payment_percentage = 30
    @loan.down_payment_amount = @loan.total_amount * 0.30
    @loan.financed_amount = @loan.total_amount - @loan.down_payment_amount
    assert @loan.valid?
  end

  test "loan with maximum down payment" do
    @loan.down_payment_percentage = 50
    @loan.down_payment_amount = @loan.total_amount * 0.50
    @loan.financed_amount = @loan.total_amount - @loan.down_payment_amount
    assert @loan.valid?
  end

  test "loan with minimum installments (6)" do
    @loan.number_of_installments = 6
    assert @loan.valid?
  end

  test "loan with maximum installments (12)" do
    @loan.number_of_installments = 12
    assert @loan.valid?
  end

  # Defaults
  test "status defaults to draft" do
    new_loan = Loan.new(
      customer: @customer,
      user: @user,
      contract_number: "TEST-DEFAULT",
      total_amount: 1000,
      approved_amount: 1000,
      down_payment_percentage: 30,
      down_payment_amount: 300,
      financed_amount: 700,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01"
    )
    assert_equal "draft", new_loan.status
  end
end
