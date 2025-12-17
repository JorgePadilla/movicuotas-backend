# frozen_string_literal: true

class PasswordsController < ApplicationController
  skip_before_action :authenticate

  def new
    # Request password reset form
  end

  def create
    user = User.find_by(email: params[:email])

    if user
      # Generate reset token (placeholder)
      token = SecureRandom.hex(32)
      # In a real implementation, store token in user with expiry
      # Send email with reset link
      PasswordMailer.reset(user, token).deliver_later
    end

    # Always show success to prevent email enumeration
    redirect_to login_path, notice: "Si el email existe, recibirás instrucciones"
  end

  def edit
    # Reset password form (with token)
    @token = params[:token]
  end

  def update
    # Update password with token
    # Placeholder implementation
    redirect_to login_path, notice: "Contraseña actualizada correctamente"
  end
end