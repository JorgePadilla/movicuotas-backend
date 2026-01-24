require "test_helper"

class LoanFinalizationServiceTest < ActiveSupport::TestCase
  setup do
    # Use existing supervisor user from fixtures
    @supervisor = users(:supervisor) || User.find_by(email: "supervisor@movicuotas.com")
    # Create a customer for testing
    @customer = Customer.create!(
      identification_number: "1234567890123",
      full_name: "Cliente Test",
      date_of_birth: Date.new(1990, 1, 1),
      phone: "12345678",
      city: "Test City",
      department: "Test Department",
      address: "Test Address"
    )
    # Create an approved credit application
    @credit_application = CreditApplication.create!(
      customer: @customer,
      vendor: @supervisor,
      status: :approved,
      approved_amount: 5000.00,
      application_number: "APP-#{Time.current.strftime('%Y%m%d')}-999999"
    )
    # Create a device (phone) not assigned to any loan
    # Note: Lock status is managed via DeviceLockState, devices start unlocked by default
    @device = Device.create!(
      imei: "123456789012345",
      brand: "Test Brand",
      model: "Test Model",
      phone_model: PhoneModel.first || PhoneModel.create!(brand: "Test Brand", model: "Test Model", storage: 128, color: "Black", price: 5000.00, active: true)
    )
    # Create a contract (unsigned initially)
    @contract = Contract.create!(
      # loan will be assigned later
    )
    # Loan attributes from payment calculator
    @loan_attributes = {
      total_amount: 5000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      interest_rate: 12.0
    }
  end

  teardown do
    # Clean up created records (optional, as test transaction rolls back)
  end

  test "should initialize service with required parameters" do
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )
    assert service
  end

  test "should raise error if credit application is not approved" do
    @credit_application.update!(status: :pending)
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )
    assert_raises LoanFinalizationError do
      service.finalize!
    end
  end

  test "should raise error if device already assigned to loan" do
    loan = Loan.create!(
      customer: @customer,
      user: @supervisor,
      branch_number: "S01",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      interest_rate: 12.0,
      start_date: Date.today,
      status: :active
    )
    @device.update!(loan: loan)
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )
    assert_raises LoanFinalizationError do
      service.finalize!
    end
  ensure
    @device.update!(loan: nil) if @device.loan.present?
  end

  test "should raise error if contract already linked to loan" do
    loan = Loan.create!(
      customer: @customer,
      user: @supervisor,
      branch_number: "S01",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      interest_rate: 12.0,
      start_date: Date.today,
      status: :active
    )
    @contract.update!(loan: loan)
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )
    assert_raises LoanFinalizationError do
      service.finalize!
    end
  ensure
    @contract.update!(loan: nil) if @contract.loan.present?
  end

  test "should raise error if customer has active loan" do
    # Create an active loan for the same customer
    Loan.create!(
      customer: @customer,
      user: @supervisor,
      branch_number: "S01",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      interest_rate: 12.0,
      start_date: Date.today,
      status: :active
    )
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )
    assert_raises LoanFinalizationError do
      service.finalize!
    end
  end

  test "should raise error if total amount exceeds approved amount" do
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes.merge(total_amount: 6000.00),
      contract: @contract,
      current_user: @supervisor
    )
    assert_raises LoanFinalizationError do
      service.finalize!
    end
  end

  test "should successfully finalize loan with valid parameters" do
    # Sign the contract first
    @contract.sign!(fixture_file_upload("test/fixtures/files/signature.png", "image/png"))

    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )

    assert_difference [ "Loan.count", "Installment.count" ], 1 do
      # Loan count increases by 1, Installment count increases by number_of_installments
      # Actually installment count increases by 6, but assert_difference with specific number
      # We'll handle separately
    end

    # Use separate assertion for installments
    assert_difference "Installment.count", @loan_attributes[:number_of_installments] do
      @loan = service.finalize!
    end

    assert @loan.persisted?
    assert_equal "active", @loan.status
    assert_equal @customer, @loan.customer
    assert_equal @device, @loan.device
    assert_equal @contract, @loan.contract
    assert_equal @loan_attributes[:total_amount], @loan.total_amount
    assert_equal @loan_attributes[:down_payment_percentage], @loan.down_payment_percentage
    assert_equal @loan_attributes[:number_of_installments], @loan.number_of_installments

    # Verify installments were created
    assert_equal @loan_attributes[:number_of_installments], @loan.installments.count
    @loan.installments.each_with_index do |installment, index|
      assert_equal index + 1, installment.installment_number
      assert_equal "pending", installment.status
      assert installment.amount > 0
      # Due date should be bi-weekly (every 14 days)
      expected_due_date = @loan.start_date + ((index + 1) * 14).days
      assert_equal expected_due_date, installment.due_date
    end

    # Verify device assigned
    assert_equal @loan, @device.reload.loan

    # Verify contract linked
    assert_equal @loan, @contract.reload.loan
  end

  test "should create audit log after successful finalization" do
    @contract.sign!(fixture_file_upload("test/fixtures/files/signature.png", "image/png"))
    service = LoanFinalizationService.new(
      credit_application: @credit_application,
      device: @device,
      loan_attributes: @loan_attributes,
      contract: @contract,
      current_user: @supervisor
    )

    assert_difference "AuditLog.count", 1 do
      @loan = service.finalize!
    end

    audit_log = AuditLog.last
    assert_equal @supervisor, audit_log.user
    assert_equal "loan_finalized", audit_log.action
    assert_equal @loan, audit_log.resource
    assert audit_log.changes.present?
  end
end
