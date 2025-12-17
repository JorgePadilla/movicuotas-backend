# frozen_string_literal: true

module Admin
  class DashboardPolicy < ::DashboardPolicy
    def index?
      user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end