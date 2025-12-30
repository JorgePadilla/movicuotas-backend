# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      Rails.logger.info "DashboardController#index - current_user: #{current_user&.email}, role: #{current_user&.role}, admin?: #{current_user&.admin?}"
      authorize nil, policy_class: Admin::DashboardPolicy
      # Placeholder for admin dashboard
    end

    private

    def pundit_policy_class
      Admin::DashboardPolicy
    end
  end
end
