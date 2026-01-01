# frozen_string_literal: true

module Admin
  class PaymentsPolicy < ApplicationPolicy
    # Only admins can view all payments system-wide
    def index?
      admin?
    end

    def show?
      admin?
    end

    class Scope < Scope
      def resolve
        user&.admin? ? scope.all : scope.none
      end
    end
  end
end
