module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      before_action :authenticate_api_user
      rescue_from Pundit::NotAuthorizedError, with: :unauthorized_error
      rescue_from ActiveRecord::RecordNotFound, with: :not_found_error
      rescue_from ActionController::ParameterMissing, with: :bad_request_error

      private

      def authenticate_api_user
        token = extract_token_from_header
        return unauthorized_error("No token provided") unless token

        decoded = decode_token(token)
        return unauthorized_error("Invalid token") unless decoded

        @current_customer = Customer.find_by(id: decoded[:customer_id])
        return unauthorized_error("Customer not found") unless @current_customer
      end

      def extract_token_from_header
        return nil unless request.headers["Authorization"].present?

        request.headers["Authorization"].split(" ").last
      end

      def decode_token(token)
        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
        payload.with_indifferent_access
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end

      def current_customer
        @current_customer
      end
      helper_method :current_customer

      def pundit_user
        current_customer
      end

      def unauthorized_error(message = "Unauthorized")
        render json: { error: message }, status: :unauthorized
      end

      def not_found_error(exception)
        render json: { error: "#{exception.model} not found" }, status: :not_found
      end

      def bad_request_error(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { error: message }, status: status
      end

      def render_success(data = {}, status = :ok)
        render json: data, status: status
      end
    end
  end
end
