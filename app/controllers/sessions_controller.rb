class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [ :new, :create ]
  skip_after_action :verify_authorized, only: [ :new, :create ]
  layout "login", only: [ :new, :create ]

  def new
    # Login form
  end

  def create
    Rails.logger.info "SessionsController#create - Starting login for email: #{params[:email]}"

    begin
      authorize Session  # Login is public, policy allows create? true
      Rails.logger.info "SessionsController#create - Authorization passed"
    rescue Pundit::NotAuthorizedError => e
      Rails.logger.error "SessionsController#create - Authorization failed: #{e.message}"
      raise
    end

    email = params[:email]&.strip
    password = params[:password]&.strip

    # Sanitized email for logging (show first 3 chars only)
    log_email = email.present? ? "#{email[0..2]}...#{email.split('@').last}" : "blank"
    Rails.logger.info "SessionsController#create - Login attempt for email: #{log_email}"

    user = email.present? ? User.where("email ILIKE ?", email).first : nil

    if user
      Rails.logger.info "SessionsController#create - User found: id=#{user.id}, active=#{user.active}, role=#{user.role}"
      auth_result = user.authenticate(password)
      user_active = user.active
    else
      Rails.logger.warn "SessionsController#create - User NOT FOUND for email: #{log_email}"
      auth_result = false
      user_active = false
    end

    Rails.logger.info "SessionsController#create - Password present: #{password.present?}, length: #{password&.length}"
    Rails.logger.info "SessionsController#create - Authentication result: #{auth_result.inspect}"

    if auth_result && user_active
      Rails.logger.info "SessionsController#create - Authentication SUCCESS for user #{user.id}"
      session = user.sessions.create!

      # Handle "Remember me" checkbox
      remember_me = params[:remember_me] == "1"
      Rails.logger.info "SessionsController#create - Remember me checked: #{remember_me}"

      if remember_me
        # Permanent cookie: expires in 30 days
        cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      else
        # Session cookie: expires when browser closes
        cookies.signed[:session_token] = { value: session.id, httponly: true }
      end

      redirect_to after_sign_in_path_for(user), notice: "Sesión iniciada correctamente"
    elsif auth_result && !user_active
      Rails.logger.warn "SessionsController#create - User #{user.id} is not active"
      flash.now[:alert] = "Tu cuenta está desactivada. Contacta al administrador."
      render :new, status: :unprocessable_entity
    else
      # Authentication failed (wrong password or user not found)
      Rails.logger.warn "SessionsController#create - Authentication FAILED - User: #{user&.id || 'not found'}, Active: #{user_active}, Auth result: #{auth_result.inspect}"
      flash.now[:alert] = "Email o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Current.session if Current.session
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Sesión cerrada"
  end

  private

  def after_sign_in_path_for(user)
    root_path  # HomeController will redirect based on role
  end
end
