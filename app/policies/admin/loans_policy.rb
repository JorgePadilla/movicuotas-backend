# frozen_string_literal: true

module Admin
  class LoansPolicy < ApplicationPolicy
    # Only admins can view all loans system-wide
    def index?
      admin?
    end

    def show?
      admin?
    end

    class Scope < Scope
      def resolve
        (user&.admin? || user&.master?) ? scope.all : scope.none
      end
    end
  end
end
