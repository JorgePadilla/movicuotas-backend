# frozen_string_literal: true

require "aws-sdk-sns"

class SmsService
  HONDURAS_COUNTRY_CODE = "+504"

  def initialize
    @client = Aws::SNS::Client.new(
      region: ENV.fetch("AWS_REGION", "us-east-1"),
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  end

  def configured?
    ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
  end

  def send_otp(phone_number:, code:, customer_name:)
    formatted_phone = format_phone(phone_number)
    message = "MOVICUOTAS: Tu codigo de verificacion es #{code}. Valido por 10 minutos."

    # In development/test, log the message instead of sending
    unless configured?
      Rails.logger.warn("[SmsService] AWS SNS not configured. Would send OTP #{code} to #{formatted_phone}")
      return mock_response if Rails.env.development? || Rails.env.test?
      return { success: false, error: "AWS SNS no configurado" }
    end

    # Skip actual sending in development/test even if configured
    if Rails.env.development? || Rails.env.test?
      Rails.logger.info("[SmsService] Development mode - OTP #{code} would be sent to #{formatted_phone}")
      return mock_response
    end

    response = @client.publish(
      phone_number: formatted_phone,
      message: message,
      message_attributes: {
        "AWS.SNS.SMS.SMSType" => {
          data_type: "String",
          string_value: "Transactional"
        }
      }
    )

    Rails.logger.info("[SmsService] SMS sent successfully to #{masked_phone(formatted_phone)}, message_id: #{response.message_id}")
    { success: true, message_id: response.message_id }
  rescue Aws::SNS::Errors::ServiceError => e
    Rails.logger.error("[SmsService] AWS SNS error: #{e.message}")
    { success: false, error: "Error al enviar SMS: #{e.message}" }
  rescue StandardError => e
    Rails.logger.error("[SmsService] Unexpected error: #{e.message}")
    { success: false, error: "Error al enviar SMS" }
  end

  private

  def format_phone(phone_number)
    # Remove any non-digit characters
    digits = phone_number.to_s.gsub(/\D/, "")

    # If phone already has country code (504...), add +
    if digits.start_with?("504") && digits.length == 11
      "+#{digits}"
    # If phone is 8 digits (Honduras local), add country code
    elsif digits.length == 8
      "#{HONDURAS_COUNTRY_CODE}#{digits}"
    # If phone already has +, return as is
    elsif phone_number.to_s.start_with?("+")
      phone_number
    else
      # Default: assume it's a local number
      "#{HONDURAS_COUNTRY_CODE}#{digits}"
    end
  end

  def masked_phone(phone)
    return "***" if phone.nil? || phone.length < 4
    "***#{phone[-4..]}"
  end

  def mock_response
    { success: true, message_id: "dev-#{SecureRandom.hex(8)}" }
  end
end
