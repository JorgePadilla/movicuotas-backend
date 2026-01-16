require "test_helper"

module Api
  module V1
    class NotificationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = Customer.create!(
          identification_number: "1234567890127",
          full_name: "Test Customer 5",
          date_of_birth: 30.years.ago,
          phone: "52345678",
          email: "test5@example.com",
          gender: "male",
          status: "active"
        )

        @token = generate_token(@customer)

        Notification.create!(
          customer: @customer,
          title: "Test Notification",
          message: "This is a test notification",
          notification_type: "general"
        )
      end

      test "index returns customer notifications" do
        get api_v1_notifications_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)

        assert data["notifications"].present?
        assert data["pagination"].present?
      end

      test "index returns unauthorized without token" do
        get api_v1_notifications_url, as: :json

        assert_response :unauthorized
      end

      test "index includes pagination data" do
        get api_v1_notifications_url, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)
        pagination = data["pagination"]

        assert_equal 1, pagination["current_page"]
        assert pagination["total_pages"].present?
        assert pagination["total_count"].present?
        assert pagination["per_page"].present?
      end

      test "index respects page parameter" do
        # Create multiple notifications
        5.times do |i|
          Notification.create!(
            customer: @customer,
            title: "Test #{i}",
            message: "Message #{i}",
            notification_type: "general"
          )
        end

        get api_v1_notifications_url, params: { page: 2, per_page: 2 }, headers: { "Authorization" => "Bearer #{@token}" }, as: :json

        assert_response :success
        data = JSON.parse(@response.body)

        assert_equal 2, data["pagination"]["current_page"]
        assert_equal 2, data["pagination"]["per_page"]
      end

      private

      def generate_token(customer)
        payload = {
          customer_id: customer.id,
          exp: 30.days.from_now.to_i,
          iat: Time.now.to_i
        }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end
    end
  end
end
