# frozen_string_literal: true

module Supervisor
  class DashboardPolicy < ::DashboardPolicy
    def index?
      admin?  # Only admin and master can access supervisor dashboard
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
