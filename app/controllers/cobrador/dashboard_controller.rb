# frozen_string_literal: true

module Cobrador
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      Rails.logger.info "Cobrador::DashboardController#index - current_user: #{current_user&.email}, role: #{current_user&.role}, cobrador?: #{current_user&.cobrador?}"
      authorize nil, policy_class: Cobrador::DashboardPolicy
      # Placeholder for cobrador dashboard
    end

    private

    def pundit_policy_class
      Cobrador::DashboardPolicy
    end
  end
end
