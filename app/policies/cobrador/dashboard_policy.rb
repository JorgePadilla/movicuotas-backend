# frozen_string_literal: true

module Cobrador
  class DashboardPolicy < ::DashboardPolicy
    def index?
      user.cobrador? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end