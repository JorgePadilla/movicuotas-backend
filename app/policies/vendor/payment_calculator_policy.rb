# frozen_string_literal: true

module Vendor
  class PaymentCalculatorPolicy < ApplicationPolicy
    # Step 12: Payment Calculator - accessible to supervisors and admins
    def new?
      user.supervisor? || user.admin?
    end

    def create?
      user.supervisor? || user.admin?
    end

    def calculate?
      user.supervisor? || user.admin?
    end

    class Scope < Scope
      def resolve
        scope.none
      end
    end
  end
end
