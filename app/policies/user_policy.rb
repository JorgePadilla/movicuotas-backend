# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # User management is restricted to admins only
  # Based on MOVICUOTAS permission matrix:
  # - Admin: Can view, create, edit, delete users
  # - Vendedor: Cannot access user management
  # - Cobrador: Cannot access user management

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

  # Cobrador cannot manage users at all
  def block?
    admin?
  end

  # Scope: Only admins can see users
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
