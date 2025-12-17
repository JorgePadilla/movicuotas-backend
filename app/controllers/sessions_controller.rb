class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [ :new, :create ]

  def new
    # Login form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

      redirect_to after_sign_in_path_for(user), notice: "Sesión iniciada correctamente"
    else
      flash.now[:alert] = "Email o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Sesión cerrada"
  end

  private

  def after_sign_in_path_for(user)
    case user.role
    when "admin"
      admin_dashboard_path
    when "vendedor"
      vendor_customer_search_path  # Main screen for vendors
    when "cobrador"
      cobrador_dashboard_path
    else
      root_path
    end
  end
end
