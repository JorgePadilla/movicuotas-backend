# frozen_string_literal: true

module Supervisor
  class DashboardPolicy < ::DashboardPolicy
    def index?
      supervisor? || admin?  # admin? includes master
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
