# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize :dashboard
      # Placeholder for admin dashboard
    end
  end
end