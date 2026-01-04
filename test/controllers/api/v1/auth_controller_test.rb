require "test_helper"

module Api
  module V1
    class AuthControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(
          email: "vendor1@test.com",
          full_name: "Test Vendor",
          password: "password123",
          role: "supervisor"
        )

        @customer = Customer.create!(
          identification_number: "1234567890123",
          full_name: "Test Customer",
          date_of_birth: 30.years.ago,
          phone: "12345678",
          email: "test@example.com",
          gender: "male",
          status: "active"
        )

        @phone_model = PhoneModel.create!(
          model: "iPhone 14",
          brand: "Apple",
          price: 800.00,
          active: true
        )

        @loan = Loan.create!(
          customer: @customer,
          user: @user,
          contract_number: "CONT-001",
          total_amount: 900.00,
          approved_amount: 900.00,
          down_payment_percentage: 30,
          down_payment_amount: 270.00,
          financed_amount: 630.00,
          interest_rate: 12.5,
          number_of_installments: 12,
          start_date: Date.today,
          end_date: 12.months.from_now,
          branch_number: "BR01",
          status: "active"
        )

        @device = Device.create!(
          loan: @loan,
          phone_model: @phone_model,
          imei: "123456789012345",
          brand: "Apple",
          model: "iPhone 14",
          lock_status: "unlocked"
        )
      end

      test "login with valid credentials returns token" do
        post api_v1_auth_login_url, params: {
          auth: {
            identification_number: @customer.identification_number,
            contract_number: @loan.contract_number
          }
        }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)

        assert data["token"].present?
        assert_equal @customer.full_name, data["customer"]["full_name"]
        assert_equal @loan.contract_number, data["loan"]["contract_number"]
      end

      test "login with invalid identification number returns unauthorized" do
        post api_v1_auth_login_url, params: {
          auth: {
            identification_number: "0000000000000",
            contract_number: @loan.contract_number
          }
        }, as: :json

        assert_response :unauthorized
      end

      test "login with invalid contract number returns unauthorized" do
        post api_v1_auth_login_url, params: {
          auth: {
            identification_number: @customer.identification_number,
            contract_number: "INVALID"
          }
        }, as: :json

        assert_response :unauthorized
      end

      test "forgot_contract sends SMS for valid phone" do
        get api_v1_auth_forgot_contract_url, params: { phone: @customer.phone }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)
        assert data["message"].include?("Contract number sent")
      end

      test "forgot_contract returns not found for invalid phone" do
        get api_v1_auth_forgot_contract_url, params: { phone: "00000000" }, as: :json

        assert_response :not_found
      end

      test "forgot_contract returns not found when no active loan" do
        customer_no_loan = Customer.create!(
          identification_number: "9876543210987",
          full_name: "Customer With No Loan",
          date_of_birth: 30.years.ago,
          phone: "99999999",
          email: "noloan@example.com",
          gender: "male",
          status: "active"
        )

        get api_v1_auth_forgot_contract_url, params: { phone: customer_no_loan.phone }, as: :json

        assert_response :not_found
      end
    end
  end
end
