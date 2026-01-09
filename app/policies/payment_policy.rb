# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  # Payment management policies based on MOVICUOTAS permission matrix:
  #
  # Roles:
  # - Admin: Full access to all payments
  # - Supervisor: View all, verify/reject all (NOT branch-limited)
  # - Vendedor: View/register own branch only, cannot verify/reject

  def index?
    true  # All authenticated users can view payments (scope will filter)
  end

  def show?
    # Admin and Supervisor can see all, Vendedor only own branch
    admin? || supervisor? || (vendedor? && own_branch_payment?)
  end

  def create?
    # Admin and Vendedor can register payments
    admin? || vendedor?
  end

  def update?
    # Only Admin and Supervisor can update payments
    # Vendedores cannot modify payment records after creation
    admin? || supervisor?
  end

  def destroy?
    admin?  # Only admin can delete payments
  end

  # Verify payment - Admin and Supervisor only (Supervisor NOT branch-limited)
  def verify?
    admin? || supervisor?
  end

  # Reject payment - Admin and Supervisor only (Supervisor NOT branch-limited)
  def reject?
    admin? || supervisor?
  end

  # Scope: Filter payments based on role
  # - Admin: All payments
  # - Supervisor: All payments (NOT branch-limited)
  # - Vendedor: Only payments for loans in their branch
  class Scope < Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      elsif user&.vendedor?
        # Vendedores can only see payments for loans in their branch
        scope.joins(loan: :customer)
             .where(loans: { branch_number: user.branch_number })
      else
        scope.none
      end
    end
  end

  private

  def own_branch_payment?
    record.loan.branch_number == user.branch_number
  end
end
