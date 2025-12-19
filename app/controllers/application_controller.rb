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
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

  private

  def skip_authorization?
    # Skip authorization for public controllers (pages, passwords)
    # Sessions controller handles authorization per-action with skip_after_action
    controller_name == "pages" || controller_name == "passwords"
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

  def user_not_authorized(exception)
    Rails.logger.error "Pundit NotAuthorizedError: #{exception.message}"
    Rails.logger.error "Policy: #{exception.policy&.class}, query: #{exception.query}"
    Rails.logger.error "Backtrace: #{exception.backtrace.first(5).join('\n')}"

    flash[:alert] = "No estás autorizado para realizar esta acción."
    redirect_back fallback_location: root_path
  end

  def invalid_authenticity_token(exception)
    Rails.logger.error "CSRF Token Error: #{exception.message}"
    Rails.logger.error "Controller: #{controller_name}, Action: #{action_name}"
    Rails.logger.error "Request format: #{request.format}"
    Rails.logger.error "Authenticity token in params: #{params[:authenticity_token].present?}"
    Rails.logger.error "Session cookie present: #{cookies[:session_token].present?}"
    Rails.logger.error "Session cookie value: #{cookies[:session_token]&.first(20)}..." if cookies[:session_token].present?
    Rails.logger.error "Headers: #{request.headers['X-CSRF-Token'].present? ? 'X-CSRF-Token present' : 'No X-CSRF-Token'}"

    flash[:alert] = "Error de seguridad. Por favor, recarga la página e intenta nuevamente."
    redirect_back fallback_location: login_path
  end

  # Override pundit user context
  def pundit_user
    current_user
  end
end
