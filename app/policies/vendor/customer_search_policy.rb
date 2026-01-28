# frozen_string_literal: true

module Vendor
  class CustomerSearchPolicy < ApplicationPolicy
    def index?
      # Vendedores, supervisors, and admins can access customer search
      vendedor? || supervisor? || admin?  # admin? includes master
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
