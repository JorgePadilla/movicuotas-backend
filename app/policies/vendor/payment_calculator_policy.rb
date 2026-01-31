# frozen_string_literal: true

module Vendor
  class PaymentCalculatorPolicy < ApplicationPolicy
    # Step 12: Payment Calculator - part of vendor workflow
    def new?
      vendedor? || supervisor? || admin?
    end

    def create?
      vendedor? || supervisor? || admin?
    end

    def calculate?
      vendedor? || supervisor? || admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
