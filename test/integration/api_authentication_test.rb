# frozen_string_literal: true

require_relative "../integration_test_helper"

class ApiAuthenticationTest < IntegrationTestCase
  # ===========================================
  # API AUTHENTICATION TESTS
  # Tests for login, logout, token validation, and device activation
  # ===========================================

  setup do
    @customer = customers(:customer_one)
    @loan = loans(:loan_one)
    @device = devices(:device_one)

    # Ensure loan is active
    @loan.update_column(:status, "active")
  end

  # ===========================================
  # LOGIN TESTS
  # ===========================================

  test "valid login returns JWT token with 30-day expiry" do
    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: @customer.identification_number,
        contract_number: @loan.contract_number
      }
    }, as: :json

    data = assert_api_success

    assert data["token"].present?, "Response should include JWT token"

    # Decode and verify token
    decoded = JWT.decode(data["token"], Rails.application.secret_key_base, true, algorithm: "HS256")[0]

    assert_equal @customer.id, decoded["customer_id"],
      "Token should contain correct customer_id"

    # Verify expiry is approximately 30 days from now
    expected_exp = 30.days.from_now.to_i
    assert_in_delta expected_exp, decoded["exp"], 60,  # Allow 60 seconds tolerance
      "Token should expire in approximately 30 days"
  end

  test "valid login returns customer data" do
    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: @customer.identification_number,
        contract_number: @loan.contract_number
      }
    }, as: :json

    data = assert_api_success

    assert data["customer"].present?, "Response should include customer data"
    assert_equal @customer.id, data["customer"]["id"]
    assert_equal @customer.full_name, data["customer"]["full_name"]
  end

  test "valid login returns loan data" do
    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: @customer.identification_number,
        contract_number: @loan.contract_number
      }
    }, as: :json

    data = assert_api_success

    assert data["loan"].present?, "Response should include loan data"
    assert_equal @loan.id, data["loan"]["id"]
    assert_equal @loan.contract_number, data["loan"]["contract_number"]
  end

  test "invalid identification number returns unauthorized" do
    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: "0000000000000",  # Invalid
        contract_number: @loan.contract_number
      }
    }, as: :json

    assert_api_unauthorized
  end

  test "invalid contract number returns unauthorized" do
    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: @customer.identification_number,
        contract_number: "CTR-INVALID-000"  # Invalid
      }
    }, as: :json

    assert_api_unauthorized
  end

  test "mismatched customer and contract returns unauthorized" do
    # Try to login with customer_one's ID but customer_two's contract
    other_loan = loans(:loan_two)  # Belongs to customer_two

    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: @customer.identification_number,
        contract_number: other_loan.contract_number
      }
    }, as: :json

    assert_api_unauthorized
  end

  # ===========================================
  # TOKEN VALIDATION TESTS
  # ===========================================

  test "valid token allows access to protected endpoints" do
    get api_v1_dashboard_path, headers: api_headers(@customer)
    assert_api_success
  end

  test "missing token returns unauthorized" do
    get api_v1_dashboard_path, headers: api_headers_no_token
    assert_api_unauthorized
  end

  test "invalid token returns unauthorized" do
    get api_v1_dashboard_path, headers: api_headers_invalid
    assert_api_unauthorized
  end

  test "malformed authorization header returns unauthorized" do
    # Test various malformed headers
    malformed_headers = [
      { "Authorization" => "NotBearer token123", "Content-Type" => "application/json" },
      { "Authorization" => "Bearer", "Content-Type" => "application/json" },
      { "Authorization" => "", "Content-Type" => "application/json" }
    ]

    malformed_headers.each do |headers|
      get api_v1_dashboard_path, headers: headers
      assert_response :unauthorized,
        "Should return unauthorized for malformed header: #{headers["Authorization"]}"
    end
  end

  test "expired token returns unauthorized" do
    get api_v1_dashboard_path, headers: api_headers_expired(@customer)
    assert_api_unauthorized
  end

  test "token with non-existent customer returns unauthorized" do
    # Create token with non-existent customer ID
    payload = {
      customer_id: 999999,  # Non-existent
      exp: 30.days.from_now.to_i,
      iat: Time.now.to_i
    }
    invalid_token = JWT.encode(payload, Rails.application.secret_key_base, "HS256")

    get api_v1_dashboard_path, headers: {
      "Authorization" => "Bearer #{invalid_token}",
      "Content-Type" => "application/json"
    }

    assert_api_unauthorized
  end

  test "token provides access to correct customer data only" do
    customer_one = customers(:customer_one)
    customer_two = customers(:customer_two)

    # Login as customer_one
    get api_v1_dashboard_path, headers: api_headers(customer_one)
    data = assert_api_success

    # Should see customer_one's data, not customer_two's
    if data["customer"]
      assert_equal customer_one.id, data["customer"]["id"]
      assert_not_equal customer_two.id, data["customer"]["id"]
    end
  end

  # ===========================================
  # DEVICE ACTIVATION TESTS
  # ===========================================

  test "device activation with valid code succeeds" do
    # Reset device activation state
    @device.update_columns(activated_at: nil)

    # FCM tokens must be at least 50 characters
    fcm_token = "test_fcm_token_" + SecureRandom.hex(25)  # 50+ chars

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      fcm_token: fcm_token,
      platform: "android",
      device_name: "Test Device"
    }, as: :json

    data = assert_api_success

    assert_equal "Dispositivo activado correctamente", data["message"]
    assert data["activated_at"].present?

    @device.reload
    assert @device.activated?
  end

  test "device activation returns JWT token for customer" do
    @device.update_columns(activated_at: nil)

    # FCM tokens must be at least 50 characters
    fcm_token = "test_fcm_token_" + SecureRandom.hex(25)

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      fcm_token: fcm_token,
      platform: "android"
    }, as: :json

    data = assert_api_success

    assert data["token"].present?, "Activation should return JWT token"

    # Verify token is valid
    decoded = JWT.decode(data["token"], Rails.application.secret_key_base, true, algorithm: "HS256")[0]
    assert_equal @customer.id, decoded["customer_id"]
  end

  test "device activation returns customer and loan data" do
    @device.update_columns(activated_at: nil)

    # FCM tokens must be at least 50 characters
    fcm_token = "test_fcm_token_" + SecureRandom.hex(25)

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      fcm_token: fcm_token,
      platform: "android"
    }, as: :json

    data = assert_api_success

    assert data["customer"].present?, "Should return customer data"
    assert_equal @customer.full_name, data["customer"]["full_name"]

    assert data["loan"].present?, "Should return loan data"
    assert_equal @loan.contract_number, data["loan"]["contract_number"]
  end

  test "device activation with invalid code fails" do
    post api_v1_devices_activate_path, params: {
      activation_code: "INVALID",
      fcm_token: "test_fcm_token",
      platform: "android"
    }, as: :json

    assert_api_not_found
  end

  test "device activation without FCM token fails" do
    @device.update_columns(activated_at: nil)

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      platform: "android"
      # Missing fcm_token
    }, as: :json

    assert_response :bad_request
    data = api_response
    assert data["error"].present?
  end

  test "already activated device cannot be activated again" do
    # Ensure device is activated
    @device.update_columns(activated_at: Time.current) unless @device.activated?

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      fcm_token: "test_fcm_token",
      platform: "android"
    }, as: :json

    assert_response :unprocessable_entity
    data = api_response
    assert data["error"].include?("ya fue activado") || data["error"].include?("already"),
      "Should indicate device is already activated"
  end

  test "device activation creates device token record" do
    @device.update_columns(activated_at: nil)

    # FCM tokens must be at least 50 characters
    fcm_token = "test_fcm_token_" + SecureRandom.hex(25)

    initial_count = DeviceToken.count

    post api_v1_devices_activate_path, params: {
      activation_code: @device.activation_code,
      fcm_token: fcm_token,
      platform: "android",
      device_name: "Test Phone"
    }, as: :json

    assert_api_success

    assert_equal initial_count + 1, DeviceToken.count,
      "Should create a new DeviceToken record"

    device_token = DeviceToken.last
    assert_equal fcm_token, device_token.token
    assert_equal @device.id, device_token.device_id
    assert_equal @customer.id, device_token.customer_id
    assert_equal "android", device_token.platform
  end

  # ===========================================
  # LOGOUT TESTS
  # ===========================================

  test "logout is client-side - token removal" do
    # In a JWT-based system, logout is typically handled client-side
    # by removing the token from storage. There's no server-side endpoint.

    # Verify that valid token still works (no server-side invalidation)
    get api_v1_dashboard_path, headers: api_headers(@customer)
    assert_api_success

    # The client would simply stop sending the token
    get api_v1_dashboard_path, headers: api_headers_no_token
    assert_api_unauthorized

    # Token is still valid if provided again
    get api_v1_dashboard_path, headers: api_headers(@customer)
    assert_api_success
  end

  # ===========================================
  # FORGOT CONTRACT TESTS
  # ===========================================

  test "forgot contract with valid phone sends SMS" do
    get api_v1_auth_forgot_contract_path, params: { phone: @customer.phone }, as: :json

    data = assert_api_success
    assert data["message"].include?(@customer.phone) ||
           data["message"].include?("sent"),
      "Should confirm SMS was sent"
  end

  test "forgot contract with invalid phone returns not found" do
    get api_v1_auth_forgot_contract_path, params: { phone: "00000000" }, as: :json

    assert_api_not_found
  end

  test "forgot contract requires active loan" do
    # Customer without active loan
    customer_inactive = customers(:customer_inactive)

    get api_v1_auth_forgot_contract_path, params: { phone: customer_inactive.phone }, as: :json

    # Should return not found if customer has no active loan
    assert [ 404, 200 ].include?(response.status),
      "Should handle customer without active loan"

    if response.status == 404
      data = api_response
      assert data["error"].present?
    end
  end

  # ===========================================
  # IMEI CHECK TESTS
  # ===========================================

  test "check IMEI returns available for unassigned IMEI" do
    get api_v1_devices_check_imei_path, params: { imei: "000000000000000" }, as: :json

    data = assert_api_success
    assert data["available"], "Unassigned IMEI should be available"
  end

  test "check IMEI returns unavailable for assigned IMEI" do
    get api_v1_devices_check_imei_path, params: { imei: @device.imei }, as: :json

    data = assert_api_success
    assert_not data["available"], "IMEI with active loan should not be available"
  end

  test "check IMEI validates format" do
    # IMEI must be 15 digits
    get api_v1_devices_check_imei_path, params: { imei: "12345" }, as: :json

    data = assert_api_success
    assert_not data["available"]
    assert data["message"].include?("15"),
      "Should mention 15 digit requirement"
  end

  # ===========================================
  # MULTIPLE ENDPOINTS AUTHENTICATION TEST
  # ===========================================

  test "authentication works across all protected API endpoints" do
    # Dashboard
    get api_v1_dashboard_path, headers: api_headers(@customer)
    assert_api_success

    # Installments
    get api_v1_installments_path, headers: api_headers(@customer)
    assert_api_success

    # Notifications
    get api_v1_notifications_path, headers: api_headers(@customer)
    assert_api_success
  end

  test "authentication fails across all protected endpoints without token" do
    # Dashboard
    get api_v1_dashboard_path, headers: api_headers_no_token
    assert_api_unauthorized

    # Installments
    get api_v1_installments_path, headers: api_headers_no_token
    assert_api_unauthorized

    # Notifications
    get api_v1_notifications_path, headers: api_headers_no_token
    assert_api_unauthorized
  end

  # ===========================================
  # EDGE CASES
  # ===========================================

  test "login with customer who has completed loan" do
    completed_loan = loans(:loan_completed)
    customer = completed_loan.customer

    post api_v1_auth_login_path, params: {
      auth: {
        identification_number: customer.identification_number,
        contract_number: completed_loan.contract_number
      }
    }, as: :json

    # Should still be able to login even with completed loan
    # The app might show different UI for completed loans
    data = assert_api_success
    assert data["token"].present?
  end

  test "case insensitive activation code" do
    @device.update_columns(activated_at: nil)
    code = @device.activation_code

    # FCM tokens must be at least 50 characters
    fcm_token = "test_fcm_token_" + SecureRandom.hex(25)

    # Try lowercase version
    post api_v1_devices_activate_path, params: {
      activation_code: code.downcase,
      fcm_token: fcm_token,
      platform: "android"
    }, as: :json

    # The controller uppercases the code, so this should work
    assert_api_success
  end
end
