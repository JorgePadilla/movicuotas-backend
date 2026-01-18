# frozen_string_literal: true

module Vendor
  class DashboardPolicy < ::DashboardPolicy
    def index?
      # Vendedores, supervisors, and admins can access vendor dashboard
      user.vendedor? || user.supervisor? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
