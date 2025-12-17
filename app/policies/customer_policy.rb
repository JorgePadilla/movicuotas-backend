# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
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
    admin? || vendedor? # Cobrador CANNOT update
  end

  def destroy?
    admin? # Cobrador CANNOT delete
  end

  def block?
    admin? # Only admin can block customers
  end

  # Scope for customer access
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.vendedor?
        # Vendedores can see customers in their branch
        scope.joins(:loans).where(loans: { branch_number: user.branch_number }).distinct
      elsif user.cobrador?
        # Cobradores can see all customers (read-only)
        scope.all
      else
        scope.none
      end
    end
  end
end