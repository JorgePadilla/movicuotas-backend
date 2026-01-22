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
        assert_nil json["token"], "Should NOT return JWT token (login required after)"
        assert_nil json["customer"], "Should NOT return customer data"
        assert_nil json["loan"], "Should NOT return loan data"

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
    end
  end
end
