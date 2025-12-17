# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    admin? || vendedor? # Cobrador CANNOT create
  end

  def update?
    admin? # Cobrador CANNOT update
  end

  def destroy?
    admin? # Cobrador CANNOT delete
  end

  # Scope for payment access
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.vendedor?
        # Vendedores can see payments for loans in their branch
        scope.joins(loan: :customer)
             .where(loans: { branch_number: user.branch_number })
      elsif user.cobrador?
        # Cobradores can see all payments (read-only)
        scope.all
      else
        scope.none
      end
    end
  end
end