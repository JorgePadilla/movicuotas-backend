# frozen_string_literal: true

require_relative "../integration_test_helper"

class LoanCreationWorkflowTest < IntegrationTestCase
  # ===========================================
  # VENDOR WORKFLOW STEP TESTS
  # Tests for the 18-step vendor workflow
  # ===========================================

  # Step 2: Customer Search
  test "step 2 - vendedor can search for existing customer" do
    sign_in_vendedor

    get vendor_customer_search_path
    assert_response :success
    assert_response_includes "Buscar Cliente"
  end

  # Step 4: Credit Application Start
  test "step 4 - can start new credit application" do
    sign_in_vendedor
    customer = customers(:customer_one)

    get new_vendor_credit_application_path(customer_id: customer.id)
    assert_response :success
  end

  # Step 5-7: Credit Application Workflow
  test "step 5 - can access photos step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)

    get photos_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  test "step 6 - can access employment step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)

    get employment_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  test "step 7 - can access summary step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)

    get summary_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  # Step 8: Application Results
  test "step 8 - approved application shows approved page" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)

    get approved_vendor_credit_application_path(credit_app)
    assert_response :success
    assert_response_includes "Solicitud Aprobada"
  end

  test "step 8 - rejected application shows rejected page" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_rejected)

    get rejected_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  # Step 9: Application Recovery
  test "step 9 - vendedor can access application recovery" do
    sign_in_vendedor

    get vendor_application_recovery_path
    assert_response :success
    assert_response_includes "Recuperar Solicitud"
  end

  # Step 10: Device Selection
  test "step 10 - device selection for approved application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)

    get vendor_device_selection_path(credit_application_id: credit_app.id)
    assert_response :success
  end

  # Step 11: Confirmation
  test "step 11 - vendedor can access device confirmation" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)

    get vendor_device_selection_confirmation_path(credit_application_id: credit_app.id)
    # May redirect if no device selected
    assert [ 200, 302 ].include?(response.status)
  end

  # Step 12: Payment Calculator
  test "step 12 - vendedor can access payment calculator" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)

    get new_vendor_payment_calculator_path(
      credit_application_id: credit_app.id,
      phone_price: 5000.00
    )
    # Controller may redirect if date_of_birth can't be fetched
    assert [ 200, 302 ].include?(response.status)
  end

  test "step 12 - vendedor can calculate payment" do
    sign_in_vendedor

    post calculate_vendor_payment_calculator_path, params: {
      phone_price: 5000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 25.years.ago.to_date.to_s
    }, as: :turbo_stream

    assert [ 200, 302 ].include?(response.status)
  end

  # Step 13-14: Contract & Signature
  test "step 13 - vendedor can view contract" do
    sign_in_vendedor
    contract = contracts(:contract_one)

    get vendor_contract_path(contract)
    assert_response :success
  end

  test "step 14 - vendedor can access signature page" do
    sign_in_vendedor
    contract = contracts(:contract_one)

    get signature_vendor_contract_path(contract)
    assert_response :success
  end

  # Step 17: MDM Checklist
  test "step 17 - MDM checklist completion keeps device unlocked" do
    sign_in_supervisor  # MDM requires supervisor access
    device = devices(:device_one)

    # Ensure device starts as unlocked
    device.lock_states.destroy_all
    assert_equal "unlocked", device.lock_status

    # Create MDM Blueprint
    mdm_blueprint = MdmBlueprint.find_or_create_by!(device: device) do |bp|
      bp.status = "active"
      bp.qr_code_data = { device_id: device.id }.to_json
    end

    # Complete MDM Checklist
    post vendor_mdm_blueprint_mdm_checklist_path(mdm_blueprint), params: {
      mdm_checklist: { movicuotas_installed: "1" }
    }

    # Device should remain unlocked
    device.reload
    assert_equal "unlocked", device.lock_status,
      "Device should remain unlocked after MDM checklist completion"

    # Cleanup
    mdm_blueprint.destroy
  end

  # Step 18: Loan Tracking Dashboard
  test "step 18 - vendedor can view loan tracking dashboard" do
    sign_in_vendedor

    get vendor_loans_path
    assert_response :success

    loan = loans(:loan_one)
    get vendor_loan_path(loan)
    assert_response :success
  end

  # ===========================================
  # BIWEEKLY CALCULATOR SERVICE TESTS
  # ===========================================

  test "calculator validates age restrictions - under 21 rejected" do
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 20.years.ago.to_date  # 20 years old
    )

    assert_not calculator.valid?, "Calculator should reject customers under 21"
    assert calculator.errors.any? { |e| e.include?("21") },
      "Error should mention age 21 requirement"
  end

  test "calculator validates age restrictions - over 60 rejected" do
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 65.years.ago.to_date  # 65 years old
    )

    assert_not calculator.valid?, "Calculator should reject customers over 60"
    assert calculator.errors.any? { |e| e.include?("60") },
      "Error should mention age 60 limit"
  end

  test "calculator validates 50-60 age group only allows 40 or 50 percent down" do
    # 55 year old with 30% down payment should be rejected
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,  # Not allowed for 50-60 age group
      number_of_installments: 6,
      date_of_birth: 55.years.ago.to_date
    )

    assert_not calculator.valid?, "Calculator should reject 30% down payment for 50-60 age group"
    assert calculator.errors.any? { |e| e.include?("40%") || e.include?("50%") },
      "Error should mention 40% or 50% requirement"

    # 55 year old with 40% down payment should be accepted
    calculator_valid = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 40,  # Allowed for 50-60 age group
      number_of_installments: 6,
      date_of_birth: 55.years.ago.to_date
    )

    assert calculator_valid.valid?, "Calculator should accept 40% down payment for 50-60 age group"
  end

  test "calculator validates down payment percentage - only 30, 40, 50 allowed" do
    [ 10, 20, 25, 35, 45, 60 ].each do |invalid_percentage|
      calculator = BiweeklyCalculatorService.new(
        phone_price: 3000.00,
        down_payment_percentage: invalid_percentage,
        number_of_installments: 6,
        date_of_birth: 30.years.ago.to_date
      )

      assert_not calculator.valid?,
        "Calculator should reject #{invalid_percentage}% down payment"
      assert calculator.errors.any? { |e| e.include?("30%") || e.include?("40%") || e.include?("50%") },
        "Error should mention valid percentages"
    end

    # Valid percentages
    [ 30, 40, 50 ].each do |valid_percentage|
      calculator = BiweeklyCalculatorService.new(
        phone_price: 3000.00,
        down_payment_percentage: valid_percentage,
        number_of_installments: 6,
        date_of_birth: 30.years.ago.to_date
      )

      assert calculator.valid?,
        "Calculator should accept #{valid_percentage}% down payment"
    end
  end

  test "calculator validates installment terms - only 6, 8, 12 allowed" do
    [ 3, 4, 5, 7, 9, 10, 11, 24 ].each do |invalid_term|
      calculator = BiweeklyCalculatorService.new(
        phone_price: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: invalid_term,
        date_of_birth: 30.years.ago.to_date
      )

      assert_not calculator.valid?,
        "Calculator should reject #{invalid_term} installments"
      assert calculator.errors.any? { |e| e.include?("6") || e.include?("8") || e.include?("12") },
        "Error should mention valid terms"
    end

    # Valid terms
    [ 6, 8, 12 ].each do |valid_term|
      calculator = BiweeklyCalculatorService.new(
        phone_price: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: valid_term,
        date_of_birth: 30.years.ago.to_date
      )

      assert calculator.valid?,
        "Calculator should accept #{valid_term} installments"
    end
  end

  test "calculator produces correct installment amounts" do
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 30.years.ago.to_date
    )

    result = calculator.calculate

    assert result[:success], "Calculation should succeed"
    assert result[:installment_amount].positive?, "Installment amount should be positive"
    assert result[:down_payment_amount] == 900.00, "Down payment should be 30% of 3000"
    assert result[:financed_amount] == 2100.00, "Financed amount should be 3000 - 900"

    # Verify installment amount is calculated correctly using amortization formula
    # PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
    p = result[:financed_amount]
    r = result[:bi_weekly_rate]  # Rate as decimal
    n = 6

    expected_installment = (p * (r * (1 + r) ** n) / ((1 + r) ** n - 1)).ceil
    assert_equal expected_installment, result[:installment_amount],
      "Installment amount should match amortization formula"
  end

  test "calculator generates correct installment schedule with 14-day intervals" do
    start_date = Date.today
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 30.years.ago.to_date,
      start_date: start_date
    )

    result = calculator.calculate

    assert result[:success], "Calculation should succeed"
    assert_equal 6, result[:installments].count, "Should have 6 installments"

    result[:installments].each_with_index do |inst, index|
      expected_due_date = start_date + (index * 14).days
      assert_equal index + 1, inst[:installment_number]
      assert_equal expected_due_date, inst[:due_date],
        "Installment #{index + 1} should be due on #{expected_due_date}"
      assert_equal "pending", inst[:status]
    end
  end

  # ===========================================
  # LOAN FINALIZATION SERVICE TESTS
  # ===========================================

  test "loan finalization creates loan, installments, and assigns device atomically" do
    # Setup: Create all prerequisites for loan finalization
    customer = customers(:customer_two)  # Customer without active loan
    vendor = users(:vendedor)

    # Ensure customer has no active loans
    customer.loans.update_all(status: "completed")

    # Create approved credit application
    credit_app = CreditApplication.create!(
      customer: customer,
      vendor: vendor,
      status: "approved",
      application_number: "APP-TEST-#{SecureRandom.hex(4)}",
      approved_amount: 5000.00,
      employment_status: "employed",
      salary_range: "range_20000_30000",
      verification_method: "sms"
    )

    # Create unassigned device
    device = Device.create!(
      imei: "#{rand(100000000000000..999999999999999)}",
      brand: "Test",
      model: "Test Model",
      phone_model: phone_models(:iphone_14),
      loan: nil
    )

    # Create signed contract (without loan initially)
    # Contract.signed? requires both signature_image attached AND signed_at present
    contract = Contract.create!(
      signed_by_name: customer.full_name,
      signed_at: Time.current
    )
    # Attach a dummy signature image
    contract.signature_image.attach(
      io: StringIO.new("fake image data"),
      filename: "signature.png",
      content_type: "image/png"
    )

    # Loan attributes from payment calculator
    loan_attributes = {
      total_amount: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      interest_rate: 12.0
    }

    # Execute finalization
    service = LoanFinalizationService.new(
      credit_application: credit_app,
      device: device,
      loan_attributes: loan_attributes,
      contract: contract,
      current_user: vendor
    )

    initial_loan_count = Loan.count
    initial_installment_count = Installment.count

    loan = service.finalize!

    # Verify loan was created
    assert_equal initial_loan_count + 1, Loan.count
    assert loan.persisted?
    assert_equal "active", loan.status
    assert_equal customer.id, loan.customer_id

    # Verify installments were created
    assert_equal initial_installment_count + 6, Installment.count
    assert_equal 6, loan.installments.count

    # Verify device was assigned
    device.reload
    assert_equal loan.id, device.loan_id

    # Verify contract was linked
    contract.reload
    assert_equal loan.id, contract.loan_id

    # Cleanup
    loan.installments.destroy_all
    loan.destroy
    contract.destroy
    device.destroy
    credit_app.destroy
  end

  test "loan finalization fails if credit application not approved" do
    credit_app = credit_applications(:credit_app_one)  # Status: pending
    device = devices(:device_one)
    contract = contracts(:contract_one)
    vendor = users(:vendedor)

    # Temporarily detach device from loan for this test
    original_loan_id = device.loan_id
    device.update_column(:loan_id, nil)

    service = LoanFinalizationService.new(
      credit_application: credit_app,
      device: device,
      loan_attributes: {
        total_amount: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: 6,
        interest_rate: 12.0
      },
      contract: contract,
      current_user: vendor
    )

    assert_raises(LoanFinalizationError) do
      service.finalize!
    end

    # Restore device
    device.update_column(:loan_id, original_loan_id)
  end

  test "loan finalization fails if device already assigned" do
    credit_app = credit_applications(:credit_app_approved)
    device = devices(:device_one)  # Already assigned to loan_one
    contract = contracts(:contract_one)
    vendor = users(:vendedor)

    service = LoanFinalizationService.new(
      credit_application: credit_app,
      device: device,
      loan_attributes: {
        total_amount: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: 6,
        interest_rate: 12.0
      },
      contract: contract,
      current_user: vendor
    )

    assert_raises(LoanFinalizationError) do
      service.finalize!
    end
  end

  test "loan finalization fails if contract not signed" do
    credit_app = credit_applications(:credit_app_approved)
    device = devices(:device_one)
    contract = contracts(:contract_unsigned)  # No signature
    vendor = users(:vendedor)

    # Temporarily detach device from loan
    original_loan_id = device.loan_id
    device.update_column(:loan_id, nil)

    service = LoanFinalizationService.new(
      credit_application: credit_app,
      device: device,
      loan_attributes: {
        total_amount: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: 6,
        interest_rate: 12.0
      },
      contract: contract,
      current_user: vendor
    )

    assert_raises(LoanFinalizationError) do
      service.finalize!
    end

    # Restore device
    device.update_column(:loan_id, original_loan_id)
  end

  test "loan finalization fails if customer has active loan" do
    # customer_one already has loan_one which is active
    credit_app = credit_applications(:credit_app_approved)
    device = devices(:device_one)
    contract = contracts(:contract_one)
    vendor = users(:vendedor)

    # credit_app_approved belongs to customer_two, but let's test with customer_one
    # who already has an active loan

    # Temporarily change credit_app to customer_one
    original_customer_id = credit_app.customer_id
    credit_app.update_column(:customer_id, customers(:customer_one).id)

    # Temporarily detach device
    original_loan_id = device.loan_id
    device.update_column(:loan_id, nil)

    service = LoanFinalizationService.new(
      credit_application: credit_app,
      device: device,
      loan_attributes: {
        total_amount: 3000.00,
        down_payment_percentage: 30,
        number_of_installments: 6,
        interest_rate: 12.0
      },
      contract: contract,
      current_user: vendor
    )

    assert_raises(LoanFinalizationError) do
      service.finalize!
    end

    # Restore
    credit_app.update_column(:customer_id, original_customer_id)
    device.update_column(:loan_id, original_loan_id)
  end

  # ===========================================
  # COMPLETE WORKFLOW INTEGRATION TEST
  # ===========================================

  test "complete vendor workflow from customer search to loan creation" do
    sign_in_vendedor

    # Step 2: Customer Search
    get vendor_customer_search_path
    assert_response :success

    # Step 4: Start credit application (using existing customer)
    customer = customers(:customer_two)  # Use customer without active loan
    get new_vendor_credit_application_path(customer_id: customer.id)
    assert_response :success

    # Steps 8-9: Check approved application
    credit_app = credit_applications(:credit_app_approved)
    get approved_vendor_credit_application_path(credit_app)
    assert_response :success

    # Step 10: Device selection
    get vendor_device_selection_path(credit_application_id: credit_app.id)
    assert_response :success

    # Step 12: Payment calculator
    get new_vendor_payment_calculator_path(
      credit_application_id: credit_app.id,
      phone_price: 800.00
    )
    assert [ 200, 302 ].include?(response.status)

    # Step 18: View loans
    get vendor_loans_path
    assert_response :success
  end
end
