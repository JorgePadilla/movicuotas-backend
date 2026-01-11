# frozen_string_literal: true

class OtpVerificationService
  HONDURAS_COUNTRY_CODE = "+504"

  attr_reader :credit_application, :errors

  def initialize(credit_application)
    @credit_application = credit_application
    @errors = []
  end

  # Main entry point: Generate and send OTP
  def send_otp
    @errors = []

    unless valid_verification_method?
      @errors << "Metodo de verificacion invalido"
      return { success: false, errors: @errors }
    end

    unless can_send?
      @errors << "Debes esperar #{credit_application.time_until_resend} segundos para reenviar"
      return { success: false, errors: @errors }
    end

    raw_code = credit_application.generate_otp!

    delivery_result = case credit_application.verification_method
    when "whatsapp"
      send_via_whatsapp(raw_code)
    when "email"
      send_via_email(raw_code)
    else
      { success: false, error: "Metodo no soportado" }
    end

    if delivery_result[:success]
      credit_application.update!(otp_delivery_status: :sent)
      log_otp_event("otp_sent", { method: credit_application.verification_method })
      { success: true, message: delivery_message }
    else
      credit_application.update!(otp_delivery_status: :failed)
      @errors << delivery_result[:error]
      log_otp_event("otp_send_failed", { method: credit_application.verification_method, error: delivery_result[:error] })
      { success: false, errors: @errors }
    end
  end

  # Verify submitted OTP code
  def verify(submitted_code)
    @errors = []

    result = credit_application.verify_otp(submitted_code)

    case result[:error]
    when :expired
      @errors << "El codigo ha expirado. Por favor solicita uno nuevo."
      log_otp_event("otp_expired")
    when :max_attempts
      @errors << "Demasiados intentos fallidos. Por favor solicita un nuevo codigo."
      log_otp_event("otp_max_attempts_reached")
    when :invalid
      @errors << "Codigo incorrecto. Te quedan #{result[:attempts_remaining]} intentos."
      log_otp_event("otp_invalid_attempt", { attempts_remaining: result[:attempts_remaining] })
    when :no_code
      @errors << "No hay codigo de verificacion. Por favor solicita uno nuevo."
    end

    if result[:success]
      log_otp_event("otp_verified")
      { success: true }
    else
      { success: false, errors: @errors }
    end
  end

  private

  def valid_verification_method?
    %w[whatsapp email].include?(credit_application.verification_method)
  end

  def can_send?
    credit_application.can_resend_otp?
  end

  def customer
    @customer ||= credit_application.customer
  end

  def formatted_phone
    # Phone stored as 8 digits, prepend Honduras code
    "#{HONDURAS_COUNTRY_CODE}#{customer.phone}"
  end

  def send_via_whatsapp(code)
    Rails.logger.info("[OtpVerificationService] Sending WhatsApp OTP to: #{formatted_phone}")
    WhatsappService.new.send_otp(
      phone_number: formatted_phone,
      code: code,
      customer_name: customer.full_name
    )
  rescue StandardError => e
    Rails.logger.error("[OtpVerificationService] WhatsApp delivery failed: #{e.message}")
    { success: false, error: "Error al enviar por WhatsApp: #{e.message}" }
  end

  def send_via_email(code)
    OtpMailer.verification_code(
      credit_application: credit_application,
      code: code
    ).deliver_now

    { success: true }
  rescue StandardError => e
    Rails.logger.error("[OtpVerificationService] Email delivery failed: #{e.message}")
    { success: false, error: "Error al enviar correo electronico" }
  end

  def delivery_message
    case credit_application.verification_method
    when "whatsapp"
      "Codigo enviado por WhatsApp al #{masked_phone}"
    when "email"
      "Codigo enviado al correo #{masked_email}"
    end
  end

  def masked_phone
    phone = customer.phone
    "****#{phone[-4..]}"
  end

  def masked_email
    email = customer.email
    return "" unless email
    parts = email.split("@")
    return email if parts.length != 2 || parts[0].length < 3
    "#{parts[0][0..2]}***@#{parts[1]}"
  end

  def log_otp_event(action, metadata = {})
    Rails.logger.info("[OTP] #{action} for credit_application #{credit_application.id}: #{metadata}")
  end
end
