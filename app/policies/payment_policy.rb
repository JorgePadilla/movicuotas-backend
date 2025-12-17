# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  # Payment management policies based on MOVICUOTAS permission matrix:
  # - View payments: All roles (Admin, Vendedor, Cobrador read-only)
  # - Register payment: Admin and Vendedor
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
    admin? || vendedor?  # Admin and Vendedor can register payments
  end

  def update?
    admin? || (vendedor? && own_payment?)  # Admin and Vendedor (own only) can update
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
  # - Vendedor: Payments for loans they created
  # - Cobrador: All payments (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.vendedor?
        # Assuming payment belongs to loan, and loan belongs to user (vendedor)
        scope.joins(loan: :user).where(loans: { user: user })
      else
        scope.none
      end
    end
  end

  private

  def own_payment?
    # Assuming payment belongs to loan, and loan belongs to user (vendedor)
    record.loan.user == user
  end
end
