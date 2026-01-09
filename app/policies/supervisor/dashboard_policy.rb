# frozen_string_literal: true

module Supervisor
  class DashboardPolicy < ::DashboardPolicy
    def index?
      user.supervisor? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
