# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  # Payment management policies based on MOVICUOTAS permission matrix:
  # - View payments: All roles (Admin, Supervisor, Cobrador read-only)
  # - Register payment: Admin and Supervisor
  # - Verify payment: Admin only
  # - Delete payment: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view payments (scope will filter)
  end

  def show?
    true  # All authenticated users can view payment details
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can register payments
  end

  def update?
    admin? || (supervisor? && own_payment?)  # Admin and Supervisor (own only) can update
  end

  def destroy?
    admin?  # Only admin can delete payments
  end

  # Custom actions
  def verify?
    admin?  # Only admin can verify payments
  end

  # Scope: Filter payments based on role
  # - Admin: All payments
  # - Supervisor: Payments for loans in their branch
  # - Cobrador: All payments (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.supervisor?
        # Supervisors can see payments for loans in their branch
        scope.joins(loan: :customer)
             .where(loans: { branch_number: user.branch_number })
      else
        scope.none
      end
    end
  end

  private

  def own_payment?
    # Assuming payment belongs to loan, and loan belongs to user (supervisor)
    record.loan.user == user
  end
end
