# frozen_string_literal: true

module Cobrador
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize :dashboard
      # Placeholder for cobrador dashboard
    end
  end
end
