# frozen_string_literal: true

class PasswordMailer < ApplicationMailer
  default from: "no-reply@movicuotas.com"

  def reset(user, token)
    @user = user
    @token = token
    @reset_url = edit_password_url(token: token)

    mail(to: @user.email, subject: "Restablecer contraseña - MOVICUOTAS")
  end
end
