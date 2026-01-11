# frozen_string_literal: true

require "net/http"
require "json"

class WhatsappService
  WHATSAPP_API_URL = "https://graph.facebook.com/v18.0"

  # Message template name must be pre-approved in WhatsApp Business Manager
  OTP_TEMPLATE_NAME = "movicuotas_otp_verification"

  def initialize
    @phone_number_id = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", nil)
    @access_token = ENV.fetch("WHATSAPP_ACCESS_TOKEN", nil)
  end

  def configured?
    @phone_number_id.present? && @access_token.present?
  end

  def send_otp(phone_number:, code:, customer_name:)
    unless configured?
      Rails.logger.warn("[WhatsappService] WhatsApp API not configured. Would send OTP #{code} to #{phone_number}")
      # In development/test, simulate success
      return { success: true, message_id: "dev-#{SecureRandom.hex(8)}" } if Rails.env.development? || Rails.env.test?
      return { success: false, error: "WhatsApp API no configurado" }
    end

    response = send_template_message(
      to: phone_number,
      template_name: OTP_TEMPLATE_NAME,
      components: [
        {
          type: "body",
          parameters: [
            { type: "text", text: customer_name },
            { type: "text", text: code }
          ]
        }
      ]
    )

    if response[:success]
      Rails.logger.info("[WhatsappService] OTP sent successfully to #{masked_phone(phone_number)}")
      { success: true, message_id: response[:message_id] }
    else
      Rails.logger.error("[WhatsappService] Failed to send OTP: #{response[:error]}")
      { success: false, error: response[:error] }
    end
  end

  private

  def send_template_message(to:, template_name:, components:)
    uri = URI("#{WHATSAPP_API_URL}/#{@phone_number_id}/messages")
    formatted_phone = to.gsub(/\D/, "") # Remove non-digits

    payload = {
      messaging_product: "whatsapp",
      to: formatted_phone,
      type: "template",
      template: {
        name: template_name,
        language: { code: "es" },
        components: components
      }
    }

    # Debug logging
    Rails.logger.info("[WhatsappService] Sending to phone_number_id: #{@phone_number_id}")
    Rails.logger.info("[WhatsappService] Recipient: #{formatted_phone}")
    Rails.logger.info("[WhatsappService] Template: #{template_name}")
    Rails.logger.info("[WhatsappService] Request URI: #{uri}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri.path, {
      "Authorization" => "Bearer #{@access_token}",
      "Content-Type" => "application/json"
    })
    request.body = payload.to_json

    response = http.request(request)
    body = JSON.parse(response.body)

    # Debug response
    Rails.logger.info("[WhatsappService] Response status: #{response.code}")
    Rails.logger.info("[WhatsappService] Response body: #{body.to_json}")

    if response.is_a?(Net::HTTPSuccess) && body["messages"]
      { success: true, message_id: body["messages"].first["id"] }
    else
      error_message = body.dig("error", "message") || "Error desconocido de WhatsApp API"
      error_code = body.dig("error", "code")
      Rails.logger.error("[WhatsappService] Error code: #{error_code}, message: #{error_message}")
      { success: false, error: error_message }
    end
  rescue JSON::ParserError => e
    Rails.logger.error("[WhatsappService] JSON parse error: #{e.message}")
    { success: false, error: "Error al procesar respuesta de WhatsApp" }
  rescue Net::TimeoutError, Net::OpenTimeout => e
    Rails.logger.error("[WhatsappService] Timeout: #{e.message}")
    { success: false, error: "Tiempo de espera agotado al conectar con WhatsApp" }
  rescue StandardError => e
    Rails.logger.error("[WhatsappService] HTTP error: #{e.message}")
    { success: false, error: "Error de conexion con WhatsApp" }
  end

  def masked_phone(phone)
    return "***" if phone.nil? || phone.length < 4
    "***#{phone[-4..]}"
  end
end
