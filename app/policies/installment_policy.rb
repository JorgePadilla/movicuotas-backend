# frozen_string_literal: true

class InstallmentPolicy < ApplicationPolicy
  # Installment management policies
  # Installments are generated automatically when a loan is created
  # - View installments: All authenticated users (via loan access)
  # - Create installments: Admin only (automatic generation)
  # - Update installments: Admin only (status updates via payments)
  # - Delete installments: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view installments (scope will filter via loan)
  end

  def show?
    true  # All authenticated users can view installment details
  end

  def create?
    admin?  # Only admin can create installments (automatic generation)
  end

  def update?
    admin?  # Only admin can manually update installments
  end

  def destroy?
    admin?  # Only admin can delete installments
  end

  # Scope: Filter installments based on loan access
  # - Admin: All installments
  # - Vendedor: Installments for loans they created
  # - Cobrador: All installments (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.vendedor?
        # Assuming installment belongs to loan, and loan belongs to user (vendedor)
        scope.joins(loan: :user).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end
