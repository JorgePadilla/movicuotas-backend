# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  # Customer management policies based on MOVICUOTAS permission matrix:
  # - View customers: All roles (Admin, Supervisor, Cobrador read-only)
  # - Create customers: Admin and Supervisor
  # - Edit customers: Admin and Supervisor
  # - Delete customers: Admin only
  # - Block customers: Admin only

  # Default CRUD actions (inherited from ApplicationPolicy):
  # - index?: true (all authenticated users)
  # - show?: true (all authenticated users)
  # - create?: admin? || supervisor?
  # - update?: admin? || supervisor?
  # - destroy?: admin?

  # Custom actions
  def block?
    admin?  # Only admin can block customers
  end

  # Scope: All authenticated users can see all customers
  # (Supervisors need to search across all stores)
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
