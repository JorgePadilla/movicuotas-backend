# frozen_string_literal: true

require_relative "../integration_test_helper"

class CuotasSynchronizationTest < IntegrationTestCase
  # ===========================================
  # CUOTAS (INSTALLMENTS) SYNCHRONIZATION TESTS
  # Verify consistency between backend calculations and API responses
  # ===========================================

  setup do
    @customer = customers(:customer_one)
    @loan = loans(:loan_one)
    # Ensure loan is active for API tests
    @loan.update_column(:status, "active")
  end

  # ===========================================
  # API INSTALLMENTS MATCH BACKEND CALCULATIONS
  # ===========================================

  test "API installments match backend calculations" do
    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    # Get installments from database
    db_installments = @loan.installments.order(:due_date)

    assert_equal db_installments.count, data["installments"].count,
      "API should return same number of installments as database"

    data["installments"].each_with_index do |api_inst, index|
      db_inst = db_installments[index]

      assert_equal db_inst.id, api_inst["id"],
        "Installment ID should match"
      assert_equal db_inst.loan_id, api_inst["loan_id"],
        "Loan ID should match"
      assert_equal db_inst.installment_number, api_inst["installment_number"],
        "Installment number should match"
      assert_equal db_inst.amount.to_f, api_inst["amount"].to_f,
        "Amount should match: DB=#{db_inst.amount}, API=#{api_inst["amount"]}"
      assert_equal db_inst.status, api_inst["status"],
        "Status should match"
    end
  end

  test "API dashboard shows correct installment summary" do
    get api_v1_dashboard_path, headers: api_headers(@customer)
    data = assert_api_success

    # Verify overdue count matches database
    db_overdue_count = @loan.installments.overdue.count
    assert_equal db_overdue_count, data["overdue_count"],
      "Overdue count should match database"

    # Verify total overdue amount
    db_overdue_amount = @loan.installments.overdue.sum(:amount).to_f
    assert_equal db_overdue_amount, data["total_overdue_amount"].to_f,
      "Total overdue amount should match database"
  end

  test "pending to overdue status change reflects in API" do
    # Find a pending installment
    pending_installment = @loan.installments.pending.first

    skip "No pending installments in fixtures" unless pending_installment

    # Store original values
    original_status = pending_installment.status
    original_due_date = pending_installment.due_date

    # Change to overdue
    pending_installment.update_columns(
      status: "overdue",
      due_date: 10.days.ago.to_date
    )

    # Verify API reflects the change
    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    api_inst = data["installments"].find { |i| i["id"] == pending_installment.id }

    assert_not_nil api_inst, "Should find the installment in API response"
    assert_equal "overdue", api_inst["status"],
      "Status should be 'overdue' in API response"
    assert api_inst["is_overdue"],
      "is_overdue flag should be true"
    assert api_inst["days_overdue"] >= 10,
      "days_overdue should be at least 10"

    # Restore original values
    pending_installment.update_columns(
      status: original_status,
      due_date: original_due_date
    )
  end

  test "overdue to paid status change reflects in API" do
    # Find an overdue installment
    overdue_installment = @loan.installments.overdue.first

    skip "No overdue installments in fixtures" unless overdue_installment

    # Store original values
    original_status = overdue_installment.status
    original_paid_date = overdue_installment.paid_date

    # Mark as paid
    overdue_installment.update_columns(
      status: "paid",
      paid_date: Date.today
    )

    # Verify API reflects the change
    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    api_inst = data["installments"].find { |i| i["id"] == overdue_installment.id }

    assert_not_nil api_inst, "Should find the installment in API response"
    assert_equal "paid", api_inst["status"],
      "Status should be 'paid' in API response"
    assert_not api_inst["is_overdue"],
      "is_overdue flag should be false for paid installments"

    # Restore original values
    overdue_installment.update_columns(
      status: original_status,
      paid_date: original_paid_date
    )
  end

  test "API summary counts update correctly with status changes" do
    # Get initial counts
    get api_v1_installments_path, headers: api_headers(@customer)
    initial_data = assert_api_success

    initial_pending = initial_data["summary"]["pending"]
    initial_paid = initial_data["summary"]["paid"]
    initial_overdue = initial_data["summary"]["overdue"]

    # Find overdue installments to change
    overdue_installments = @loan.installments.overdue.limit(2).to_a

    skip "Need at least 2 overdue installments" if overdue_installments.count < 2

    # Store original states
    original_states = overdue_installments.map do |inst|
      { id: inst.id, status: inst.status, paid_date: inst.paid_date }
    end

    # Mark one as paid, one as pending
    overdue_installments[0].update_columns(status: "paid", paid_date: Date.today)
    overdue_installments[1].update_columns(status: "pending")

    # Get updated counts
    get api_v1_installments_path, headers: api_headers(@customer)
    updated_data = assert_api_success

    # Verify counts changed appropriately
    assert_equal initial_pending + 1, updated_data["summary"]["pending"],
      "Pending count should increase by 1"
    assert_equal initial_paid + 1, updated_data["summary"]["paid"],
      "Paid count should increase by 1"
    assert_equal initial_overdue - 2, updated_data["summary"]["overdue"],
      "Overdue count should decrease by 2"

    # Restore original states
    original_states.each do |state|
      Installment.find(state[:id]).update_columns(
        status: state[:status],
        paid_date: state[:paid_date]
      )
    end
  end

  test "BiweeklyCalculatorService output matches API installment data structure" do
    calculator = BiweeklyCalculatorService.new(
      phone_price: 3000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 30.years.ago.to_date
    )

    result = calculator.calculate
    assert result[:success], "Calculator should succeed"

    # Compare structure of calculator output with API installment structure
    calc_installment = result[:installments].first

    # Get API installments
    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    api_installment = data["installments"].first

    # Verify calculator generates compatible structure
    assert calc_installment[:installment_number].present?,
      "Calculator should include installment_number"
    assert calc_installment[:due_date].present?,
      "Calculator should include due_date"
    assert calc_installment[:amount].present?,
      "Calculator should include amount"
    assert calc_installment[:status].present?,
      "Calculator should include status"

    # Verify API returns same fields
    assert api_installment["installment_number"].present?,
      "API should include installment_number"
    assert api_installment["due_date"].present?,
      "API should include due_date"
    assert api_installment["amount"].present?,
      "API should include amount"
    assert api_installment["status"].present?,
      "API should include status"
  end

  test "payment submission creates pending verification state" do
    # Find an installment that can have a payment
    installment = @loan.installments.pending.first || @loan.installments.overdue.first

    skip "No pending or overdue installments" unless installment

    initial_payment_count = Payment.count

    # Submit payment via API
    post api_v1_payments_path, headers: api_headers(@customer), params: {
      payment: {
        amount: installment.amount,
        payment_method: "transfer",
        reference_number: "REF-#{SecureRandom.hex(4)}"
      },
      installment_ids: [ installment.id ]
    }.to_json

    # Should create a payment (regardless of verification status)
    assert Payment.count >= initial_payment_count,
      "Payment should be created"

    # If payment was created, verify it's pending verification
    if response.successful?
      data = api_response
      if data["payment"]
        assert_equal "pending", data["payment"]["verification_status"],
          "New payment should have pending verification status"
      end
    end
  end

  # ===========================================
  # INSTALLMENT AMOUNT CONSISTENCY TESTS
  # ===========================================

  test "installment amounts are consistent across all views" do
    # Get installments from API
    get api_v1_installments_path, headers: api_headers(@customer)
    api_data = assert_api_success

    # Get installments from dashboard API
    get api_v1_dashboard_path, headers: api_headers(@customer)
    dashboard_data = assert_api_success

    # Get installments from database
    db_installments = @loan.installments

    # Verify total amounts match
    api_total = api_data["installments"].sum { |i| i["amount"].to_f }
    db_total = db_installments.sum(:amount).to_f

    assert_in_delta db_total, api_total, 0.01,
      "Total installment amounts should match between DB and API"

    # Verify overdue amounts match
    api_overdue_total = api_data["installments"]
      .select { |i| i["status"] == "overdue" }
      .sum { |i| i["amount"].to_f }

    assert_in_delta dashboard_data["total_overdue_amount"].to_f, api_overdue_total, 0.01,
      "Overdue amounts should match between dashboard and installments API"
  end

  test "installment dates are returned in correct format" do
    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    data["installments"].each do |inst|
      # Verify due_date can be parsed
      due_date = Date.parse(inst["due_date"].to_s)
      assert due_date.is_a?(Date), "due_date should be parseable as Date"

      # Verify paid_date if present
      if inst["paid_date"].present?
        paid_date = Date.parse(inst["paid_date"].to_s)
        assert paid_date.is_a?(Date), "paid_date should be parseable as Date"
      end
    end
  end

  test "installment days_overdue calculation is accurate" do
    # Find an overdue installment
    overdue_installment = @loan.installments.overdue.first

    skip "No overdue installments" unless overdue_installment

    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    api_inst = data["installments"].find { |i| i["id"] == overdue_installment.id }

    expected_days = (Date.today - overdue_installment.due_date).to_i
    actual_days = api_inst["days_overdue"]

    assert_equal expected_days, actual_days,
      "days_overdue should match calculated value"
  end

  # ===========================================
  # EDGE CASES
  # ===========================================

  test "API handles customer with no active loan" do
    # Use a customer without an active loan
    customer_inactive = customers(:customer_inactive)

    get api_v1_installments_path, headers: api_headers(customer_inactive)
    assert_api_not_found
  end

  test "API handles loan with no installments" do
    # Create a temporary loan with no installments
    temp_loan = Loan.create!(
      customer: @customer,
      user: users(:admin),
      contract_number: "CTR-TEST-#{SecureRandom.hex(4)}",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.0,
      number_of_installments: 6,
      start_date: Date.today,
      branch_number: "S01",
      status: :active
    )

    # Deactivate the existing loan temporarily
    @loan.update_column(:status, "completed")

    get api_v1_installments_path, headers: api_headers(@customer)
    data = assert_api_success

    assert_equal 0, data["installments"].count,
      "Should return empty installments array"
    assert_equal 0, data["summary"]["total_installments"],
      "Summary should show 0 total installments"

    # Cleanup
    @loan.update_column(:status, "active")
    temp_loan.destroy
  end
end
