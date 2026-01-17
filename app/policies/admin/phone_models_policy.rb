# frozen_string_literal: true

module Admin
  class PhoneModelsPolicy < ApplicationPolicy
    # Only admins can manage phone models
    def index?
      admin?
    end

    def show?
      admin?
    end

    def create?
      admin?
    end

    def new?
      create?
    end

    def update?
      admin?
    end

    def edit?
      update?
    end

    def destroy?
      admin?
    end

    class Scope < Scope
      def resolve
        user&.admin? ? scope.all : scope.none
      end
    end
  end
end
