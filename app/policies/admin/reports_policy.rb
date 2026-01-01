# frozen_string_literal: true

module Admin
  class ReportsPolicy < ApplicationPolicy
    # Only admins can generate and view reports
    def index?
      admin?
    end

    def branch_analytics?
      admin?
    end

    def revenue_report?
      admin?
    end

    def customer_portfolio?
      admin?
    end

    def export_report?
      admin?
    end

    class Scope < Scope
      def resolve
        user&.admin? ? scope.all : scope.none
      end
    end
  end
end
