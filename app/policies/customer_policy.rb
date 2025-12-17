# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  # Customer management policies based on MOVICUOTAS permission matrix:
  # - View customers: All roles (Admin, Vendedor, Cobrador read-only)
  # - Create customers: Admin and Vendedor
  # - Edit customers: Admin and Vendedor
  # - Delete customers: Admin only
  # - Block customers: Admin only

  # Default CRUD actions (inherited from ApplicationPolicy):
  # - index?: true (all authenticated users)
  # - show?: true (all authenticated users)
  # - create?: admin? || vendedor?
  # - update?: admin? || vendedor?
  # - destroy?: admin?

  # Custom actions
  def block?
    admin?  # Only admin can block customers
  end

  # Scope: All authenticated users can see all customers
  # (Vendedors need to search across all stores)
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
