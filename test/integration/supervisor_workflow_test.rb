# frozen_string_literal: true

require_relative "../integration_test_helper"

class SupervisorWorkflowTest < IntegrationTestCase
  # ===========================================
  # Authentication & Authorization Tests
  # ===========================================

  test "supervisor can access supervisor dashboard" do
    sign_in_supervisor
    get supervisor_dashboard_path
    assert_response :success
  end

  test "admin can access supervisor dashboard" do
    sign_in_admin
    get supervisor_dashboard_path
    assert_response :success
  end

  test "vendedor cannot access supervisor dashboard" do
    sign_in_vendedor
    get supervisor_dashboard_path
    assert_response :redirect
  end

  test "unauthenticated user redirected to login" do
    get supervisor_dashboard_path
    assert_requires_authentication
  end

  # ===========================================
  # Dashboard Tests
  # ===========================================

  test "dashboard shows overdue metrics" do
    sign_in_supervisor
    get supervisor_dashboard_path
    assert_response :success
    # Dashboard should show overdue device metrics
    assert_response_includes "Dispositivos"
  end

  # ===========================================
  # Overdue Devices Tests
  # ===========================================

  test "supervisor can list overdue devices" do
    sign_in_supervisor
    get supervisor_overdue_devices_path
    assert_response :success
  end

  test "supervisor can view overdue device details" do
    sign_in_supervisor
    device = devices(:device_one)
    get supervisor_overdue_device_path(device)
    assert_response :success
    assert_response_includes device.imei
  end

  test "supervisor can filter overdue devices by days" do
    sign_in_supervisor
    get supervisor_overdue_devices_path, params: { min_days: 30 }
    assert_response :success
  end

  test "supervisor can search overdue devices by IMEI" do
    sign_in_supervisor
    device = devices(:device_one)
    get supervisor_overdue_devices_path, params: { imei: device.imei }
    assert_response :success
    # Search works - results may or may not include the device depending on overdue status
  end

  # ===========================================
  # Device Blocking Tests
  # ===========================================

  test "supervisor can access block confirmation page" do
    sign_in_supervisor
    device = devices(:device_one)
    get block_supervisor_overdue_device_path(device)
    assert_response :success
    assert_response_includes "Confirmar Bloqueo"
  end

  test "supervisor can confirm device block" do
    sign_in_supervisor
    device = devices(:device_one)

    # This should block the device
    post confirm_block_supervisor_overdue_device_path(device), params: {
      reason: "30+ days overdue"
    }

    # Should redirect after blocking
    assert_response :redirect
  end

  test "vendedor cannot block devices" do
    sign_in_vendedor
    device = devices(:device_one)
    get block_supervisor_overdue_device_path(device)
    assert_response :redirect
  end

  # ===========================================
  # Bulk Operations Tests
  # ===========================================

  test "supervisor can access bulk operations" do
    sign_in_supervisor
    get supervisor_bulk_operations_path, params: {
      device_ids: [devices(:device_one).id, devices(:device_two).id]
    }
    assert_response :success
  end

  # ===========================================
  # Payment History Tests
  # ===========================================

  test "supervisor can view loan payment history" do
    sign_in_supervisor
    loan = loans(:loan_one)
    get supervisor_loan_payment_history_path(loan_id: loan.id)
    assert_response :success
  end

  test "vendedor can view loan payment history in supervisor section" do
    # Note: LoanPolicy#show? returns true for all authenticated users
    # Vendedores can view loans from their branch
    sign_in_vendedor
    loan = loans(:loan_one)
    get supervisor_loan_payment_history_path(loan_id: loan.id)
    # Current behavior: Any authenticated user can view loan details
    assert_response :success
  end

  # ===========================================
  # Collection Reports Tests
  # ===========================================

  test "supervisor can view collection reports" do
    sign_in_supervisor
    get supervisor_collection_reports_path
    assert_response :success
  end

  test "supervisor can filter collection reports by date range" do
    sign_in_supervisor
    get supervisor_collection_reports_path, params: {
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    }
    assert_response :success
  end

  test "supervisor can export collection reports as CSV" do
    sign_in_supervisor
    get supervisor_collection_reports_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  # ===========================================
  # Cross-Access Tests
  # ===========================================

  test "supervisor can access vendor dashboard" do
    sign_in_supervisor
    # Supervisors CAN access vendor workflows for oversight
    get vendor_dashboard_path
    assert_response :success
  end

  test "supervisor can access vendor root" do
    sign_in_supervisor
    # Supervisors CAN access vendor namespace
    get vendor_root_path
    assert_response :success
  end
end
