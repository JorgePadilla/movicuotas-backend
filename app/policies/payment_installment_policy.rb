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
  # - Supervisor: All payment_installments (NOT branch-limited)
  # - Vendedor: Payment_installments for loans in their branch
  class Scope < Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      elsif user&.vendedor?
        # Vendedor sees payment_installments for loans in their branch
        scope.joins(payment: :loan).where(loans: { branch_number: user.branch_number })
      else
        scope.none
      end
    end
  end
end
