class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [ :new, :create ]
  skip_after_action :verify_authorized, only: [ :new, :create ]

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
    user = email.present? ? User.where('email ILIKE ?', email).first : nil
    Rails.logger.info "SessionsController#create - User found: #{user.present?}, user id: #{user&.id}"
    Rails.logger.info "SessionsController#create - Password param present: #{password.present?}, length: #{password&.length}"

    if user&.authenticate(password)
      Rails.logger.info "SessionsController#create - Authentication SUCCESS for user #{user.id}"
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

      redirect_to after_sign_in_path_for(user), notice: "Sesión iniciada correctamente"
    else
      Rails.logger.warn "SessionsController#create - Authentication FAILED for email: #{params[:email]}"
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
