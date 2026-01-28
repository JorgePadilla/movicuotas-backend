# frozen_string_literal: true

module Vendor
  class PaymentCalculatorPolicy < ApplicationPolicy
    # Step 12: Payment Calculator - accessible to supervisors and admins
    def new?
      supervisor? || admin?  # admin? includes master
    end

    def create?
      supervisor? || admin?
    end

    def calculate?
      supervisor? || admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
