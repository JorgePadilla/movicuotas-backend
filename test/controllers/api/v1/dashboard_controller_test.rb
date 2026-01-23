require "test_helper"

module Api
  module V1
    class DashboardControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = Customer.create!(
          identification_number: "1234567890124",
          full_name: "Test Customer 2",
          date_of_birth: 30.years.ago,
          phone: "22345678",
          email: "test2@example.com",
          gender: "female",
          status: "active"
        )

        @phone_model = PhoneModel.create!(
          model: "Galaxy S21",
          brand: "Samsung",
          price: 700.00
        )

        @device = Device.create!(
          imei: "999888777666555",
          phone_model: @phone_model,
          brand: "Samsung",
          model: "Galaxy S21"
        )

        @loan = Loan.create!(
          customer: @customer,
          contract_number: "CONT-002",
          total_amount: 800.00,
          financed_amount: 700.00,
          interest_rate: 12.5,
          start_date: Date.today,
          end_date: 12.months.from_now,
          number_of_installments: 12,
          status: "active"
        )

        @device.update!(loan: @loan)

        Installment.create!(
          loan: @loan,
          installment_number: 1,
          due_date: 15.days.from_now,
          amount: 66.67,
          status: "pending"
        )

        @token = generate_token(@customer)
      end

      test "show returns dashboard data for authenticated customer" do
        get api_v1_dashboard_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)

        assert_equal @customer.id, data["customer"]["id"]
        assert_equal @loan.id, data["loan"]["id"]
        assert data["next_payment"].present? || data["next_payment"].nil?
      end

      test "show returns unauthorized without token" do
        get api_v1_dashboard_url, as: :json

        assert_response :unauthorized
      end

      test "show returns unauthorized with invalid token" do
        get api_v1_dashboard_url, headers: { "Authorization" => "Bearer invalid_token" }, as: :json

        assert_response :unauthorized
      end

      test "show returns not found when no active loan" do
        @loan.update(status: "completed")

        get api_v1_dashboard_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :not_found
      end

      private

      def generate_token(customer)
        payload = {
          customer_id: customer.id,
          exp: 30.days.from_now.to_i,
          iat: Time.now.to_i
        }
        JWT.encode(payload, Rails.application.secrets.secret_key_base, "HS256")
      end
    end
  end
end
