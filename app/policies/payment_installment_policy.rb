# frozen_string_literal: true

class PaymentInstallmentPolicy < ApplicationPolicy
  # PaymentInstallment policies (join table linking payments to installments)
  # PaymentInstallment records are created automatically when payments are applied to installments
  # - View payment_installments: All authenticated users (via payment/installment access)
  # - Create/Update/Delete: Admin only (automatic creation via payment processing)

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view payment_installments (scope will filter via payment/installment)
  end

  def show?
    true  # All authenticated users can view payment_installment details
  end

  def create?
    admin?  # Only admin can create payment_installments (automatic via payment processing)
  end

  def update?
    admin?  # Only admin can manually update payment_installments
  end

  def destroy?
    admin?  # Only admin can delete payment_installments
  end

  # Scope: Filter payment_installments based on payment/installment access
  # - Admin: All payment_installments
  # - Supervisor: Payment_installments for payments they created
  # - Cobrador: All payment_installments (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.supervisor?
        # Assuming payment_installment belongs to payment, payment belongs to loan, loan belongs to user (supervisor)
        scope.joins(payment: { loan: :user }).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end
