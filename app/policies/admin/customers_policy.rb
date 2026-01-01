# frozen_string_literal: true

module Admin
  class CustomersPolicy < ApplicationPolicy
    # Only admins can manage customers
    def index?
      admin?
    end

    def show?
      admin?
    end

    def edit?
      admin?
    end

    def update?
      admin?
    end

    class Scope < Scope
      def resolve
        user&.admin? ? scope.all : scope.none
      end
    end
  end
end
