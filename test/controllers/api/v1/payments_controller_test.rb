require "test_helper"

module Api
  module V1
    class PaymentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = Customer.create!(
          identification_number: "1234567890126",
          full_name: "Test Customer 4",
          date_of_birth: 30.years.ago,
          phone: "42345678",
          email: "test4@example.com",
          gender: "female",
          status: "active"
        )

        @phone_model = PhoneModel.create!(
          model: "Google Pixel",
          brand: "Google",
          price: 600.00
        )

        @loan = Loan.create!(
          customer: @customer,
          contract_number: "CONT-004",
          phone_model: @phone_model,
          principal_amount: 600.00,
          total_amount: 700.00,
          interest_rate: 12.5,
          loan_period_months: 12,
          start_date: Date.today,
          end_date: 12.months.from_now,
          installment_day: 15,
          number_of_installments: 12,
          status: "active"
        )

        @installment = Installment.create!(
          loan: @loan,
          installment_number: 1,
          due_date: 15.days.from_now,
          amount: 58.33,
          status: "pending"
        )

        @token = generate_token(@customer)
      end

      test "create submits payment with valid data" do
        post api_v1_payments_url, params: {
          payment: {
            installment_id: @installment.id,
            amount: @installment.amount,
            payment_date: Date.today
          }
        }, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :created
        data = JSON.parse(@response.body)

        assert data["id"].present?
        assert_equal "pending", data["status"]
        assert data["message"].present?
      end

      test "create returns unauthorized without token" do
        post api_v1_payments_url, params: {
          payment: {
            installment_id: @installment.id,
            amount: @installment.amount,
            payment_date: Date.today
          }
        }, as: :json

        assert_response :unauthorized
      end

      test "create returns not found for invalid installment" do
        post api_v1_payments_url, params: {
          payment: {
            installment_id: 99999,
            amount: 100,
            payment_date: Date.today
          }
        }, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :not_found
      end

      test "create validates payment amount" do
        post api_v1_payments_url, params: {
          payment: {
            installment_id: @installment.id,
            amount: nil,
            payment_date: Date.today
          }
        }, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :unprocessable_entity
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
