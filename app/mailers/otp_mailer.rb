# frozen_string_literal: true

class OtpMailer < ApplicationMailer
  default from: "no-reply@movicuotas.com"

  def verification_code(credit_application:, code:)
    @customer = credit_application.customer
    @code = code
    @expiration_minutes = CreditApplication::OTP_EXPIRATION_TIME / 60

    mail(
      to: @customer.email,
      subject: "Tu codigo de verificacion MOVICUOTAS - #{@code}"
    )
  end
end
