# frozen_string_literal: true

module Admin
  class JobsPolicy < ::ApplicationPolicy
    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def retry?
      user.admin?
    end

    def trigger?
      user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
