# frozen_string_literal: true

# Root controller that redirects users based on their role
# For non-authenticated users, redirects to login without error message
class HomeController < ApplicationController
  skip_before_action :authenticate, only: :index
  before_action :load_session_if_available, only: :index
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    # If user is not logged in, redirect to login page without error message
    unless current_user
      redirect_to login_path
      return
    end

    # User is logged in - redirect based on role
    case current_user.role
    when "admin"
      redirect_to admin_dashboard_path
    when "supervisor"
      redirect_to supervisor_dashboard_path
    when "vendedor"
      redirect_to vendor_customer_search_path
    else
      redirect_to login_path
    end
  end

  private

  def pundit_policy_class
    HomePolicy
  end
end
