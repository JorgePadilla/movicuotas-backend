# frozen_string_literal: true

class InstallmentPolicy < ApplicationPolicy
  # Installment management policies
  # Installments are generated automatically when a loan is created
  # - View installments: All authenticated users (via loan access)
  # - Create installments: Admin only (automatic generation)
  # - Update installments: Admin and Supervisor (status updates, mark as paid)
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
    admin? || supervisor?  # Admin and Supervisor can update installments
  end

  def destroy?
    admin?  # Only admin can delete installments
  end

  # Mark installment as paid - Admin and Supervisor only
  def mark_paid?
    admin? || supervisor?
  end

  # Scope: Filter installments based on loan access
  # - Admin: All installments
  # - Supervisor: All installments (NOT branch-limited)
  # - Vendedor: Installments for loans in their branch
  class Scope < Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      elsif user&.vendedor?
        # Vendedor sees installments for loans in their branch
        scope.joins(:loan).where(loans: { branch_number: user.branch_number })
      else
        scope.none
      end
    end
  end
end
