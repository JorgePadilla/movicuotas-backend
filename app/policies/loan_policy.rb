# frozen_string_literal: true

class LoanPolicy < ApplicationPolicy
  # Loan management policies based on MOVICUOTAS permission matrix:
  #
  # Roles:
  # - Admin: Full access to all loans
  # - Supervisor: View all loans (NOT branch-limited), cannot create/edit
  # - Vendedor: View/create/edit own branch only

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
    master?  # Only master can delete loans (not regular admin)
  end

  def cancel?
    (admin? || master?) && !record.cancelled?
  end

  # Manual approval - Admin only (Vendedor submissions are auto-approved)
  def approve?
    admin?
  end

  def download_contract?
    show?  # If you can view the loan, you can download its contract
  end

  # Down payment collection (Vendedor collects prima from customer)
  def collect_down_payment?
    (admin? || vendedor?) && record.contract&.signed? && !record.down_payment_collected?
  end

  # Down payment verification - Admin and Supervisor
  def verify_down_payment?
    admin? || supervisor?
  end

  # Block device - Admin, Supervisor, and Vendedor can block
  def block_device?
    admin? || supervisor? || vendedor?
  end

  # Unblock device - Admin, Supervisor, and Vendedor can unblock
  def unblock_device?
    admin? || supervisor? || vendedor?
  end

  # Scope: Filter loans based on role
  # - Admin: All loans
  # - Supervisor: All loans (NOT branch-limited)
  # - Vendedor: Only loans in their branch
  class Scope < Scope
    def resolve
      if user&.master? || user&.admin? || user&.supervisor?
        scope.all
      elsif user&.vendedor?
        # Vendedores can only see loans in their branch
        scope.where(branch_number: user.branch_number)
      else
        scope.none
      end
    end
  end

  private

  def own_loan?
    # Loan belongs to the vendedor who created it
    record.user == user
  end
end
