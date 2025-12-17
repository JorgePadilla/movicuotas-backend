class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate
  after_action :verify_authorized, if: :should_verify_authorized?
  after_action :verify_policy_scoped, if: :should_verify_policy_scoped?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def skip_authorization?
    # Skip authorization for sessions and pages controllers (public pages)
    controller_name == "sessions" || controller_name == "pages"
  end

  def should_verify_policy_scoped?
    # Only verify policy scoped for index actions and if not skipping authorization
    action_name == "index" && !skip_authorization?
  end

  def should_verify_authorized?
    # Verify authorized for non-index actions and if not skipping authorization
    action_name != "index" && !skip_authorization?
  end

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

  def user_not_authorized
    flash[:alert] = "No estás autorizado para realizar esta acción."
    redirect_back fallback_location: root_path
  end

  # Override pundit user context
  def pundit_user
    current_user
  end
end
