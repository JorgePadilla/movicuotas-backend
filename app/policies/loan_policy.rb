# frozen_string_literal: true

class LoanPolicy < ApplicationPolicy
  # Loan management policies based on MOVICUOTAS permission matrix:
  # - View loans: Admin (all), Vendedor (own only), Cobrador (all)
  # - Create credit application: Admin and Vendedor
  # - Approve credit: Admin only (automatic for vendedor)
  # - Edit loans: Admin and Vendedor (own only)
  # - Delete loans: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view loans (scope will filter)
  end

  def show?
    true  # All authenticated users can view loan details
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create loans
  end

  def update?
    admin? || (vendedor? && own_loan?)  # Admin and Vendedor (own only) can update
  end

  def destroy?
    admin?  # Only admin can delete loans
  end

  # Custom actions
  def approve?
    admin?  # Only admin can manually approve loans (vendedor submissions are auto-approved)
  end

  # Scope: Filter loans based on role
  # - Admin: All loans
  # - Vendedor: Only loans they created
  # - Cobrador: All loans (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.vendedor?
        # Assuming loan has a `user` association with the vendedor who created it
        scope.where(user: user)
      else
        scope.none
      end
    end
  end

  private

  def own_loan?
    # Assuming loan has a `user` association with the vendedor who created it
    record.user == user
  end
end