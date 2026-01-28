# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # User management is restricted to admins only
  # Based on MOVICUOTAS permission matrix:
  # - Admin: Can view, create, edit, delete users
  # - Supervisor: Cannot access user management
  # - Vendedor: Cannot access user management

  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  # Only admin can block users
  def block?
    admin?
  end

  # Scope: Only admins and master can see users
  class Scope < Scope
    def resolve
      if user&.admin? || user&.master?
        scope.all
      else
        scope.none
      end
    end
  end
end
