# frozen_string_literal: true

module Admin
  class SettingsPolicy < ApplicationPolicy
    # Only admins and masters can manage settings
    def index?
      admin?
    end

    def update?
      admin?
    end

    class Scope < Scope
      def resolve
        (user&.admin? || user&.master?) ? scope.all : scope.none
      end
    end
  end
end
