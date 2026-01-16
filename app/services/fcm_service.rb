# frozen_string_literal: true

require "googleauth"
require "net/http"
require "json"

# Firebase Cloud Messaging Service
# Sends push notifications to mobile devices via FCM HTTP v1 API
#
# Usage:
#   FcmService.send_notification(
#     device_token: "fcm_token_here",
#     title: "Payment Reminder",
#     body: "Your payment is due tomorrow",
#     data: { loan_id: 123, type: "payment_reminder" }
#   )
#
# Or send to multiple devices:
#   FcmService.send_to_user(user, title: "...", body: "...", data: {})
#
class FcmService
  FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
  FCM_BASE_URL = "https://fcm.googleapis.com/v1/projects"

  class << self
    # Send notification to a single device token
    def send_notification(device_token:, title:, body:, data: {}, image: nil)
      return error_result("FCM not configured") unless configured?
      return error_result("Device token is required") if device_token.blank?

      message = build_message(device_token, title, body, data, image)
      send_fcm_request(message)
    end

    # Send notification to all active device tokens for a user
    def send_to_user(user, title:, body:, data: {}, image: nil)
      return error_result("FCM not configured") unless configured?
      return error_result("User is required") if user.nil?

      tokens = user.device_tokens.active.pluck(:token)
      return error_result("No active device tokens") if tokens.empty?

      results = tokens.map do |token|
        send_notification(device_token: token, title: title, body: body, data: data, image: image)
      end

      {
        success: results.any? { |r| r[:success] },
        total: tokens.count,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] },
        results: results
      }
    end

    # Send notification to a customer
    def send_to_customer(customer, title:, body:, data: {}, notification_type: "general")
      return error_result("Customer is required") if customer.nil?
      return error_result("FCM not configured") unless configured?

      # Get active device tokens for this customer
      tokens = customer.device_tokens.active.pluck(:token)
      return error_result("No active device tokens") if tokens.empty?

      # Send to all tokens
      results = tokens.map do |token|
        send_notification(device_token: token, title: title, body: body, data: data)
      end

      result = {
        success: results.any? { |r| r[:success] },
        total: tokens.count,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] },
        results: results
      }

      # Create notification record
      create_notification_record(customer, title, body, data, notification_type, result)

      result
    end

    # Check if FCM is properly configured
    def configured?
      credentials_path.present? && File.exist?(credentials_path)
    end

    # Get the Firebase project ID
    def project_id
      return @project_id if defined?(@project_id)

      if configured?
        creds = JSON.parse(File.read(credentials_path))
        @project_id = creds["project_id"]
      else
        @project_id = ENV["FIREBASE_PROJECT_ID"]
      end
    end

    private

    def credentials_path
      @credentials_path ||= ENV["GOOGLE_APPLICATION_CREDENTIALS"] ||
                           Rails.root.join("config", "firebase-service-account.json").to_s
    end

    def build_message(token, title, body, data, image)
      message = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body
          }.compact
        }
      }

      # Add image if provided
      message[:message][:notification][:image] = image if image.present?

      # Add data payload (must be string values)
      if data.present?
        message[:message][:data] = data.transform_values(&:to_s)
      end

      # Android-specific configuration
      message[:message][:android] = {
        priority: "high",
        notification: {
          channel_id: "movicuotas_default",
          sound: "default",
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }
      }

      # iOS-specific configuration
      message[:message][:apns] = {
        payload: {
          aps: {
            sound: "default",
            badge: 1
          }
        }
      }

      message
    end

    def send_fcm_request(message)
      uri = URI("#{FCM_BASE_URL}/#{project_id}/messages:send")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request.body = message.to_json

      response = http.request(request)

      case response.code.to_i
      when 200
        {
          success: true,
          message_id: JSON.parse(response.body)["name"],
          response: response.body
        }
      when 404
        # Token is invalid - mark it as inactive
        handle_invalid_token(message[:message][:token])
        {
          success: false,
          error: "Invalid registration token",
          error_code: "UNREGISTERED",
          response: response.body
        }
      when 429
        {
          success: false,
          error: "Rate limit exceeded",
          error_code: "QUOTA_EXCEEDED",
          response: response.body
        }
      else
        {
          success: false,
          error: "FCM request failed",
          error_code: response.code,
          response: response.body
        }
      end
    rescue StandardError => e
      Rails.logger.error("FCM Error: #{e.message}")
      {
        success: false,
        error: e.message,
        error_code: "EXCEPTION"
      }
    end

    def access_token
      @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_path),
        scope: FCM_SCOPE
      )

      # Refresh token if expired or about to expire
      if @authorizer.access_token.nil? || token_expired?
        @authorizer.fetch_access_token!
        @token_expiry = Time.current + 3500.seconds # Token valid for ~1 hour
      end

      @authorizer.access_token
    end

    def token_expired?
      @token_expiry.nil? || Time.current >= @token_expiry
    end

    def handle_invalid_token(token)
      device_token = DeviceToken.find_by(token: token)
      device_token&.invalidate
      Rails.logger.info("Invalidated FCM token: #{token[0..20]}...")
    end

    def create_notification_record(customer, title, body, data, notification_type, result)
      Notification.create(
        customer: customer,
        title: title,
        body: body,
        notification_type: notification_type,
        metadata: data.to_json,
        delivery_method: "fcm",
        status: result[:success] ? "delivered" : "failed",
        error_message: result[:error],
        sent_at: Time.current
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create notification record: #{e.message}")
    end

    def error_result(message)
      { success: false, error: message }
    end
  end
end
