class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate
  after_action :verify_authorized, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def authenticate
    if session_record = Session.find_by(id: cookies.signed[:session_token])
      Current.session = session_record
    else
      redirect_to login_path, alert: "Debes iniciar sesión"
    end
  end

  def current_user
    Current.session&.user
  end
  helper_method :current_user

  def pundit_user
    current_user
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:alert] = "No estás autorizado para realizar esta acción."
    redirect_to(request.referrer || root_path)
  end
end
