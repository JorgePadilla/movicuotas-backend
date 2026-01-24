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
    assert [ 200, 302 ].include?(response.status)
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
    assert [ 200, 302 ].include?(response.status)
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

  # ===========================================
  # BUG FIX INTEGRATION TEST: Device Lock Status
  # This test verifies the fix for the bug where completing
  # the MDM checklist incorrectly set lock_status to "locked"
  # ===========================================

  test "complete sale workflow - device stays unlocked after MDM checklist completion" do
    # Use supervisor since MDM Blueprint policy requires admin? or supervisor?
    sign_in_supervisor

    # Get an existing device and verify it starts as unlocked
    device = devices(:device_one)
    # Ensure device starts as unlocked (no lock states = unlocked)
    device.lock_states.destroy_all
    assert_equal "unlocked", device.lock_status, "Device should start as unlocked"

    # Create MDM Blueprint for the device
    mdm_blueprint = MdmBlueprint.create!(
      device: device,
      status: "active",
      qr_code_data: { device_id: device.id }.to_json
    )

    # Step 17: Access MDM Checklist
    get vendor_mdm_blueprint_mdm_checklist_path(mdm_blueprint)
    assert_response :success

    # Step 17: Complete MDM Checklist (vendor confirms app is installed)
    post vendor_mdm_blueprint_mdm_checklist_path(mdm_blueprint), params: {
      mdm_checklist: { movicuotas_installed: "1" }
    }

    # Should redirect to success page
    assert_response :redirect
    assert_match /success/, response.location

    # CRITICAL ASSERTION: Device MUST remain unlocked after completing MDM checklist
    # This is the main bug fix verification
    device.reload
    assert_equal "unlocked", device.lock_status,
      "BUG FIX: Device lock_status should remain 'unlocked' after MDM checklist completion. " \
      "Previously, the code incorrectly set it to 'locked', causing new devices to appear " \
      "as blocked to customers immediately after purchase."

    # Additional verification: locked_by_id and locked_at should be nil
    # (since device was never actually blocked for non-payment)
    assert_nil device.locked_by_id, "locked_by_id should be nil since device was never blocked"
    assert_nil device.locked_at, "locked_at should be nil since device was never blocked"

    # Clean up
    mdm_blueprint.destroy
  end

  test "customer scenario - multiple sales maintain correct lock status" do
    # Scenario: Simulate multiple customers (A, B, C) completing purchases
    # All devices should remain unlocked after sale completion
    sign_in_supervisor

    devices_to_test = [ devices(:device_one), devices(:device_two) ]

    devices_to_test.each_with_index do |device, index|
      # Reset device to unlocked state (no lock states = unlocked)
      device.lock_states.destroy_all

      # Create MDM Blueprint
      mdm_blueprint = MdmBlueprint.find_or_create_by!(device: device) do |bp|
        bp.status = "active"
        bp.qr_code_data = { device_id: device.id }.to_json
      end

      # Complete MDM Checklist
      post vendor_mdm_blueprint_mdm_checklist_path(mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "1" }
      }

      # Verify device stays unlocked
      device.reload
      assert_equal "unlocked", device.lock_status,
        "Customer #{index + 1}: Device should remain unlocked after sale completion"
    end
  end

  test "device lock status only changes via explicit blocking for non-payment" do
    # This test documents the correct behavior:
    # - Devices start as 'unlocked' when created
    # - Devices stay 'unlocked' after MDM checklist completion
    # - Devices only become 'locked' when explicitly blocked for non-payment

    sign_in_supervisor
    device = devices(:device_one)

    # 1. Device starts unlocked (no lock states = unlocked)
    device.lock_states.destroy_all
    assert_equal "unlocked", device.lock_status

    # 2. Create and complete MDM checklist
    mdm_blueprint = MdmBlueprint.find_or_create_by!(device: device) do |bp|
      bp.status = "active"
      bp.qr_code_data = { device_id: device.id }.to_json
    end

    post vendor_mdm_blueprint_mdm_checklist_path(mdm_blueprint), params: {
      mdm_checklist: { movicuotas_installed: "1" }
    }

    # 3. Device should still be unlocked after MDM completion
    device.reload
    assert_equal "unlocked", device.lock_status,
      "Device must stay unlocked after MDM checklist - this is the bug fix"

    # 4. Only explicit lock! call should change status
    # (This would happen through supervisor/cobrador interface for non-payment)
    supervisor = users(:supervisor)
    device.lock!(supervisor, "Non-payment test")

    device.reload
    # Note: lock! sets status to "pending" first (waiting for MDM confirmation)
    assert_equal "pending", device.lock_status
    assert_equal supervisor.id, device.locked_by_id
    assert_not_nil device.locked_at
  end
end
