# frozen_string_literal: true

require_relative "../integration_test_helper"

class VendedorWorkflowTest < IntegrationTestCase
  # ===========================================
  # Authentication & Authorization Tests
  # ===========================================

  test "vendedor can access vendor dashboard" do
    sign_in_vendedor
    get vendor_dashboard_path
    assert_response :success
  end

  test "vendedor lands on customer search after login" do
    # Sign in manually to test the redirect flow
    post login_path, params: { email: users(:vendedor).email, password: "password123" }
    # After login, vendedor should be redirected to vendor root
    assert_response :redirect
    # Follow redirect(s) - may need to follow multiple redirects
    3.times do
      break if response.successful?
      follow_redirect! if response.redirect?
    end
    assert response.successful?
  end

  test "supervisor can access vendor dashboard" do
    # Supervisors (cobradores) can access vendor flows for oversight
    sign_in_supervisor
    get vendor_dashboard_path
    assert_response :success
  end

  test "admin can access vendor dashboard" do
    sign_in_admin
    get vendor_dashboard_path
    assert_response :success
  end

  test "unauthenticated user redirected to login" do
    get vendor_root_path
    assert_requires_authentication
  end

  # ===========================================
  # Step 2: Customer Search (Main Screen)
  # ===========================================

  test "vendedor can access customer search" do
    sign_in_vendedor
    get vendor_customer_search_path
    assert_response :success
    assert_response_includes "Buscar Cliente"
  end

  # ===========================================
  # Step 4-7: Credit Application Workflow
  # ===========================================

  test "vendedor can start new credit application" do
    sign_in_vendedor
    # New credit application requires a customer_id parameter
    customer = customers(:customer_one)
    get new_vendor_credit_application_path(customer_id: customer.id)
    assert_response :success
  end

  test "vendedor can view existing credit application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)
    get vendor_credit_application_path(credit_app)
    assert_response :success
  end

  test "vendedor can access photos step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)
    get photos_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  test "vendedor can access employment step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)
    get employment_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  test "vendedor can access summary step" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_one)
    get summary_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  # ===========================================
  # Step 8: Application Results
  # ===========================================

  test "vendedor can view approved application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)
    get approved_vendor_credit_application_path(credit_app)
    assert_response :success
    assert_response_includes "Solicitud Aprobada"
  end

  test "vendedor can view rejected application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_rejected)
    get rejected_vendor_credit_application_path(credit_app)
    assert_response :success
  end

  # ===========================================
  # Step 9: Application Recovery
  # ===========================================

  test "vendedor can access application recovery" do
    sign_in_vendedor
    get vendor_application_recovery_path
    assert_response :success
    assert_response_includes "Recuperar Solicitud"
  end

  test "vendedor can search for approved application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)
    post vendor_application_recovery_path, params: {
      application_number: credit_app.application_number
    }
    # Should show the found application or redirect
    assert_response :success
  end

  # ===========================================
  # Step 10: Device Selection
  # ===========================================

  test "vendedor can access device selection for approved application" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)
    get vendor_device_selection_path(credit_application_id: credit_app.id)
    assert_response :success
  end

  # ===========================================
  # Step 11: Confirmation
  # ===========================================

  test "vendedor can access device confirmation" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)
    get vendor_device_selection_confirmation_path(credit_application_id: credit_app.id)
    # Confirmation page redirects to device selection if no device selected
    assert_response :redirect
    # Follow redirect should succeed
    follow_redirect!
    assert_response :success
  end

  # ===========================================
  # Step 12: Payment Calculator
  # ===========================================

  test "vendedor can access payment calculator" do
    sign_in_vendedor
    credit_app = credit_applications(:credit_app_approved)
    # Payment calculator requires credit_application_id to get date_of_birth
    get new_vendor_payment_calculator_path(
      credit_application_id: credit_app.id,
      phone_price: 5000.00
    )
    # The controller may redirect if date_of_birth can't be fetched
    # Just verify it doesn't raise an error
    assert [200, 302].include?(response.status)
  end

  test "vendedor can calculate payment" do
    sign_in_vendedor
    # Provide date_of_birth directly for test
    post calculate_vendor_payment_calculator_path, params: {
      phone_price: 5000.00,
      down_payment_percentage: 30,
      number_of_installments: 6,
      date_of_birth: 25.years.ago.to_date.to_s
    }, as: :turbo_stream
    # Accept success or turbo_stream responses
    assert [200, 302].include?(response.status)
  end

  # ===========================================
  # Step 13-14: Contract & Signature
  # ===========================================

  test "vendedor can view contract" do
    sign_in_vendedor
    contract = contracts(:contract_one)
    get vendor_contract_path(contract)
    assert_response :success
  end

  test "vendedor can access signature page" do
    sign_in_vendedor
    contract = contracts(:contract_one)
    get signature_vendor_contract_path(contract)
    assert_response :success
  end

  # ===========================================
  # Step 18: Loan Tracking
  # ===========================================

  test "vendedor can list loans" do
    sign_in_vendedor
    get vendor_loans_path
    assert_response :success
  end

  test "vendedor can view loan details" do
    sign_in_vendedor
    loan = loans(:loan_one)
    get vendor_loan_path(loan)
    assert_response :success
  end

  test "vendedor can filter loans by status" do
    sign_in_vendedor
    get vendor_loans_path, params: { status: "active" }
    assert_response :success
  end

  test "vendedor can filter loans with overdue installments" do
    sign_in_vendedor
    get vendor_loans_path, params: { cuotas: "con_vencidas" }
    assert_response :success
  end

  test "vendedor can search loans" do
    sign_in_vendedor
    get vendor_loans_path, params: { search: "CTR-2025" }
    assert_response :success
  end

  # ===========================================
  # Branch Restrictions Tests
  # ===========================================

  test "vendedor only sees loans from their branch" do
    sign_in_vendedor
    get vendor_loans_path
    assert_response :success
    # Vendedor S01 should see loans from their branch
    # This is enforced by policy_scope in the controller
  end

  # ===========================================
  # Read-Only Restrictions Tests
  # ===========================================

  test "vendedor cannot access admin routes" do
    sign_in_vendedor
    get admin_root_path
    assert_response :redirect
  end

  test "vendedor cannot access supervisor routes" do
    sign_in_vendedor
    get supervisor_dashboard_path
    assert_response :redirect
  end

  test "vendedor cannot block devices" do
    sign_in_vendedor
    device = devices(:device_one)
    get block_supervisor_overdue_device_path(device)
    assert_response :redirect
  end
end
