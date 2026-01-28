# frozen_string_literal: true

module Admin
  class DashboardPolicy < ::DashboardPolicy
    def index?
      admin?  # Uses ApplicationPolicy#admin? which includes master
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
