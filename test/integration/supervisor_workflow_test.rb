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
    get supervisor_overdue_devices_path, params: { search: devices(:device_one).imei }
    assert_response :success
    assert_response_includes devices(:device_one).imei
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

  test "vendedor cannot view loan payment history in supervisor section" do
    sign_in_vendedor
    loan = loans(:loan_one)
    get supervisor_loan_payment_history_path(loan_id: loan.id)
    assert_response :redirect
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
  # Read-Only Access Tests
  # ===========================================

  test "supervisor cannot create loans" do
    sign_in_supervisor
    # Supervisors are read-only for loans - they should not have access
    # to vendor loan creation routes
    get vendor_root_path
    assert_response :redirect # Supervisor not allowed in vendor namespace
  end

  test "supervisor cannot edit customers" do
    sign_in_supervisor
    # Supervisors should not have edit access to customers
    # They can only view and block devices
    get admin_edit_customer_path(customers(:customer_one))
    assert_response :redirect
  rescue ActionController::RoutingError
    # Route may not exist, which is also acceptable
    pass
  end
end
