# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class DevicesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @device = devices(:device_one)
        @customer = customers(:customer_one)
        @loan = loans(:loan_one)
      end

      test "activate successfully activates device with valid code" do
        assert @device.activation_code.present?, "Device should have activation code"
        assert_nil @device.activated_at, "Device should not be activated yet"

        post api_v1_devices_activate_url, params: {
          activation_code: @device.activation_code,
          fcm_token: "a" * 150, # FCM tokens are typically long
          platform: "android",
          device_name: "Test Phone"
        }, as: :json

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Dispositivo activado correctamente", json["message"]
        assert json["token"].present?, "Should return JWT token for authentication"
        assert json["activated_at"].present?, "Should return activation timestamp"

        # Customer data
        assert json["customer"].present?, "Should return customer data"
        assert_equal @customer.id, json["customer"]["id"]
        assert_equal @customer.full_name, json["customer"]["full_name"]

        # Loan data
        assert json["loan"].present?, "Should return loan data"
        assert_equal @loan.id, json["loan"]["id"]
        assert_equal @loan.contract_number, json["loan"]["contract_number"]

        @device.reload
        assert @device.activated?, "Device should be activated"
        assert_equal 1, @device.device_tokens.count, "Should have created device token"
      end

      test "activate returns error for invalid code" do
        post api_v1_devices_activate_url, params: {
          activation_code: "INVALID",
          fcm_token: "a" * 150,
          platform: "android"
        }, as: :json

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "Codigo de activacion invalido", json["error"]
      end

      test "activate returns error for already activated device" do
        @device.activate!

        post api_v1_devices_activate_url, params: {
          activation_code: @device.activation_code,
          fcm_token: "a" * 150,
          platform: "android"
        }, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "Este dispositivo ya fue activado", json["error"]
      end

      test "activate returns error without fcm_token" do
        post api_v1_devices_activate_url, params: {
          activation_code: @device.activation_code,
          platform: "android"
        }, as: :json

        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_equal "Token FCM requerido", json["error"]
      end

      test "activate normalizes code to uppercase" do
        post api_v1_devices_activate_url, params: {
          activation_code: @device.activation_code.downcase,
          fcm_token: "a" * 150,
          platform: "android"
        }, as: :json

        assert_response :success
        @device.reload
        assert @device.activated?
      end

      # ===========================================
      # check_imei endpoint tests
      # ===========================================

      test "check_imei returns available true for new IMEI" do
        new_imei = "111222333444555"
        assert_nil Device.find_by(imei: new_imei), "IMEI should not exist"

        get api_v1_devices_check_imei_url, params: { imei: new_imei }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["available"], "New IMEI should be available"
      end

      test "check_imei returns available false for IMEI with active loan" do
        # device_one has loan_one which is active
        assert_equal "active", @device.loan.status

        get api_v1_devices_check_imei_url, params: { imei: @device.imei }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_not json["available"], "IMEI with active loan should not be available"
        assert_equal "IMEI ya en uso con préstamo activo", json["message"]
      end

      test "check_imei returns available true for IMEI with cancelled loan" do
        # Create a device with a cancelled loan to test reassignment availability
        cancelled_loan = loans(:loan_two)
        cancelled_loan.update_column(:status, "cancelled")  # Use update_column to bypass validations

        device_with_cancelled = devices(:device_two)
        assert_equal "cancelled", device_with_cancelled.loan.reload.status

        get api_v1_devices_check_imei_url, params: { imei: device_with_cancelled.imei }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["available"], "IMEI with cancelled loan should be available for reassignment"
        assert_equal "IMEI disponible para reasignación", json["message"]
      end

      test "check_imei returns error for invalid IMEI format - too short" do
        get api_v1_devices_check_imei_url, params: { imei: "12345" }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_not json["available"]
        assert_equal "IMEI debe tener 15 dígitos numéricos", json["message"]
      end

      test "check_imei returns error for invalid IMEI format - non-numeric" do
        get api_v1_devices_check_imei_url, params: { imei: "12345678901234A" }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_not json["available"]
        assert_equal "IMEI debe tener 15 dígitos numéricos", json["message"]
      end

      test "check_imei returns error for empty IMEI" do
        get api_v1_devices_check_imei_url, params: { imei: "" }, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_not json["available"]
      end

      test "check_imei does not require authentication" do
        # No authentication headers, should still work
        get api_v1_devices_check_imei_url, params: { imei: "111222333444555" }, as: :json

        assert_response :success
      end
    end
  end
end
