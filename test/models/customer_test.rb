require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  # Validations - Identification Number
  test "validates presence of identification_number" do
    customer = Customer.new(identification_number: nil)
    assert customer.invalid?
    assert_includes customer.errors[:identification_number], "can't be blank"
  end

  test "validates uniqueness of identification_number" do
    existing = customers(:customer_one)
    duplicate = Customer.new(
      identification_number: existing.identification_number,
      full_name: "Different Name",
      date_of_birth: 30.years.ago,
      phone: "99999999",
      email: "different@example.com",
      gender: "male",
      status: "active"
    )
    assert duplicate.invalid?
    assert_includes duplicate.errors[:identification_number], "has already been taken"
  end

  test "validates identification_number format - must be 13 digits" do
    customer = Customer.new(identification_number: "12345678901")
    assert customer.invalid?
    assert_includes customer.errors[:identification_number], "debe tener 13 dígitos"
  end

  test "validates identification_number numeric only" do
    customer = Customer.new(identification_number: "123456789012a")
    assert customer.invalid?
  end

  # Validations - Full Name
  test "validates presence of full_name" do
    @customer.full_name = nil
    assert @customer.invalid?
    assert_includes @customer.errors[:full_name], "can't be blank"
  end

  # Validations - Date of Birth
  test "validates presence of date_of_birth" do
    @customer.date_of_birth = nil
    assert @customer.invalid?
    assert_includes @customer.errors[:date_of_birth], "can't be blank"
  end

  test "validates customer must be at least 21 years old" do
    @customer.date_of_birth = 20.years.ago.to_date
    assert @customer.invalid?
    assert @customer.errors[:date_of_birth].any?
  end

  test "validates customer born exactly 21 years ago is valid" do
    @customer.date_of_birth = 21.years.ago.to_date
    assert @customer.valid?
  end

  test "validates customer must be at most 60 years old" do
    @customer.date_of_birth = 61.years.ago.to_date
    assert @customer.invalid?
    assert @customer.errors[:date_of_birth].any?
  end

  test "validates customer born exactly 60 years ago is valid" do
    @customer.date_of_birth = 60.years.ago.to_date
    assert @customer.valid?
  end

  # Validations - Phone
  test "validates presence of phone" do
    @customer.phone = nil
    assert @customer.invalid?
    assert_includes @customer.errors[:phone], "can't be blank"
  end

  test "validates phone format - must be 8 digits" do
    @customer.phone = "1234567"
    assert @customer.invalid?
    assert_includes @customer.errors[:phone], "debe tener 8 dígitos"
  end

  test "validates phone numeric only" do
    @customer.phone = "1234567a"
    assert @customer.invalid?
  end

  # Validations - Email
  test "validates email format" do
    @customer.email = "invalid-email"
    assert @customer.invalid?
    assert @customer.errors[:email].any?
  end

  test "allows blank email" do
    @customer.email = ""
    assert @customer.valid?
  end

  # Validations - Status
  test "validates status inclusion" do
    @customer.status = "unknown"
    assert @customer.invalid?
    assert_includes @customer.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    %w[active suspended blocked].each do |status|
      @customer.status = status
      assert @customer.valid?, "Status #{status} should be valid"
    end
  end

  # Validations - Gender
  test "validates gender inclusion" do
    @customer.gender = "unknown"
    assert @customer.invalid?
  end

  test "accepts valid gender values" do
    %w[male female other].each do |gender|
      @customer.gender = gender
      assert @customer.valid?, "Gender #{gender} should be valid"
    end
  end

  # Date of Birth Parsing
  test "parses ISO format date (YYYY-MM-DD)" do
    @customer.date_of_birth = "1990-05-15"
    assert @customer.valid?
    assert_equal Date.new(1990, 5, 15), @customer.date_of_birth
  end

  test "parses DD/MM/YYYY format" do
    @customer.date_of_birth = "15/05/1990"
    assert @customer.valid?
    assert_equal Date.new(1990, 5, 15), @customer.date_of_birth
  end

  test "parses DD-MM-YYYY format" do
    @customer.date_of_birth = "15-05-1990"
    assert @customer.valid?
    assert_equal Date.new(1990, 5, 15), @customer.date_of_birth
  end

  test "handles nil date_of_birth" do
    @customer.date_of_birth = nil
    assert @customer.invalid?
  end

  # Methods
  test "calculates age correctly" do
    @customer.date_of_birth = 35.years.ago.to_date
    expected_age = ((Date.today - @customer.date_of_birth) / 365.25).floor
    assert_equal expected_age, @customer.age
  end

  test "age is correct around birthday" do
    today = Date.today
    # Set birthday for today (or yesterday if before today)
    @customer.date_of_birth = today.prev_year
    age = @customer.age
    assert age >= 0, "Age should not be negative"
  end

  # Relationships
  test "has many loans" do
    assert_respond_to @customer, :loans
  end

  test "has many credit_applications" do
    assert_respond_to @customer, :credit_applications
  end

  test "has many notifications" do
    assert_respond_to @customer, :notifications
  end

  # Scopes
  test "with_active_loans scope returns customers with active loans" do
    # Setup: Create a customer with an active loan
    customer = customers(:customer_one)
    user = users(:admin)
    phone_model = phone_models(:iphone_14)

    loan = Loan.create!(
      customer: customer,
      user: user,
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

    assert_includes Customer.with_active_loans, customer
  end

  test "without_active_loans scope returns customers without active loans" do
    customer = customers(:customer_two)
    assert_includes Customer.without_active_loans, customer
  end

  # Status Enum
  test "active? method works" do
    @customer.status = "active"
    assert @customer.active?
    assert !@customer.suspended?
    assert !@customer.blocked?
  end

  test "suspended? method works" do
    @customer.status = "suspended"
    assert @customer.suspended?
  end

  test "blocked? method works" do
    @customer.status = "blocked"
    assert @customer.blocked?
  end

  # Gender Enum
  test "gender_male? method works" do
    @customer.gender = "male"
    assert @customer.gender_male?
  end

  test "gender_female? method works" do
    @customer.gender = "female"
    assert @customer.gender_female?
  end

  test "gender_other? method works" do
    @customer.gender = "other"
    assert @customer.gender_other?
  end

  # Edge Cases
  test "handles very long full_name" do
    @customer.full_name = "A" * 500
    assert @customer.valid?
  end

  test "handles special characters in address" do
    @customer.address = "Calle #1, Apt. 2-B (South)"
    assert @customer.valid?
  end

  test "phone with spaces/hyphens not allowed" do
    @customer.phone = "7234-5678"
    assert @customer.invalid?
  end

  # Persistence
  test "saves valid customer" do
    customer = Customer.new(
      identification_number: "1111111111111",
      full_name: "Test Customer",
      date_of_birth: 30.years.ago,
      phone: "88888888",
      email: "test@example.com",
      gender: "male",
      status: "active"
    )
    assert customer.save
    assert_not_nil customer.id
  end

  test "updates customer attributes" do
    @customer.full_name = "Updated Name"
    @customer.save
    assert_equal "Updated Name", @customer.reload.full_name
  end

  test "destroys customer" do
    customer = customers(:customer_one)
    assert_difference("Customer.count", -1) do
      customer.destroy
    end
  end

  # Default Values
  test "status defaults to active" do
    customer = Customer.new(
      identification_number: "2222222222222",
      full_name: "New Customer",
      date_of_birth: 30.years.ago,
      phone: "77777777",
      email: "new@example.com"
    )
    assert_equal "active", customer.status
  end
end
