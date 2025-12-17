# frozen_string_literal: true

module Vendor
  class CustomerSearchPolicy < ApplicationPolicy
    def index?
      user.vendedor? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
