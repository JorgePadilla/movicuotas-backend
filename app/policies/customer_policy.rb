# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  # Customer management policies based on MOVICUOTAS permission matrix:
  #
  # Roles:
  # - Admin: Full access (create, edit, delete, block)
  # - Supervisor: View all customers only (read-only)
  # - Vendedor: View all, create, edit (no delete, no block)

  # All authenticated users can view customers
  def index?
    true
  end

  def show?
    true
  end

  # Admin and Vendedor can create customers
  def create?
    admin? || vendedor?
  end

  # Admin and Vendedor can edit customers
  def update?
    admin? || vendedor?
  end

  # Only admin can delete customers
  def destroy?
    admin?
  end

  # Only admin can block customers
  def block?
    admin?
  end

  # Scope: All authenticated users can see all customers
  # (Vendedores need to search across all stores for customer lookup)
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
