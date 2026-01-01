require "test_helper"

module Api
  module V1
    class InstallmentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = Customer.create!(
          identification_number: "1234567890125",
          full_name: "Test Customer 3",
          date_of_birth: 30.years.ago,
          phone: "32345678",
          email: "test3@example.com",
          gender: "male",
          status: "active"
        )

        @phone_model = PhoneModel.create!(
          model: "iPhone 15",
          brand: "Apple",
          price: 900.00
        )

        @loan = Loan.create!(
          customer: @customer,
          contract_number: "CONT-003",
          phone_model: @phone_model,
          principal_amount: 900.00,
          total_amount: 1000.00,
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
          amount: 83.33,
          status: "pending"
        )

        @token = generate_token(@customer)
      end

      test "index returns all installments for active loan" do
        get api_v1_installments_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)

        assert data["installments"].present?
        assert data["summary"]["total_installments"].present?
        assert data["summary"]["pending"].present?
        assert data["summary"]["paid"].present?
        assert data["summary"]["overdue"].present?
      end

      test "index returns unauthorized without token" do
        get api_v1_installments_url, as: :json

        assert_response :unauthorized
      end

      test "index returns not found when no active loan" do
        @loan.update(status: "completed")

        get api_v1_installments_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :not_found
      end

      test "index includes correct installment data" do
        get api_v1_installments_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)
        first_installment = data["installments"].first

        assert_equal @installment.id, first_installment["id"]
        assert_equal @installment.amount.to_s, first_installment["amount"].to_s
        assert first_installment["status"].present?
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
