# frozen_string_literal: true

module Admin
  class JobsPolicy < ::ApplicationPolicy
    def index?
      admin?  # Uses ApplicationPolicy#admin? which includes master
    end

    def show?
      admin?
    end

    def retry?
      admin?
    end

    def trigger?
      admin?
    end

    def cancel?
      admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
