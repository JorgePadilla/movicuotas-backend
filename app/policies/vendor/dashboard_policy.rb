# frozen_string_literal: true

module Vendor
  class DashboardPolicy < ::DashboardPolicy
    def index?
      # Only vendedores and admins can access vendor dashboard
      # Supervisors (cobradores) should NOT access vendor workflows
      user.vendedor? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
