# frozen_string_literal: true

class CreditApplicationPolicy < ApplicationPolicy
  # Credit Application policies based on MOVICUOTAS permission matrix:
  # - Create credit application: Admin and Vendedor
  # - Approve credit: Admin only (automatic for vendedor submissions)
  # - View applications: Admin (all), Vendedor (own only)
  # - Cobrador: Cannot access credit applications

  # Default CRUD actions (override as needed):
  def index?
    admin? || vendedor?  # Admin and Vendedor can view applications
  end

  def show?
    admin? || (vendedor? && own_application?)
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create applications
  end

  def update?
    admin? || (vendedor? && own_application?)  # Admin and Vendedor (own only) can update
  end

  def destroy?
    admin?  # Only admin can delete applications
  end

  # Custom actions
  def approve?
    admin?  # Only admin can manually approve applications (vendedor submissions auto-approved)
  end

  # Scope: Filter applications based on role
  # - Admin: All applications
  # - Vendedor: Only applications they created
  # - Cobrador: No access
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.vendedor?
        # Assuming credit_application has a `user` association with the vendedor who created it
        scope.where(user: user)
      else
        scope.none
      end
    end
  end

  private

  def own_application?
    # Assuming credit_application has a `user` association with the vendedor who created it
    record.user == user
  end
end
