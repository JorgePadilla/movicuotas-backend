# frozen_string_literal: true

# Root controller that redirects users based on their role
class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  def index
    authorize :home, :index?

    case current_user.role
    when "admin", "supervisor"
      redirect_to vendor_customer_search_path
    when "cobrador"
      redirect_to cobrador_dashboard_path
    else
      # Should not happen (authenticate ensures user is logged in)
      redirect_to login_path
    end
  end

  private

  def pundit_policy_class
    HomePolicy
  end
end
