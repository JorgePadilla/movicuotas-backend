# frozen_string_literal: true

class ContractPolicy < ApplicationPolicy
  # Contract policies (digital contracts with customer signatures)
  # - View contracts: Admin (all), Supervisor (all), Vendedor (own branch)
  # - Create contracts: Admin and Vendedor (automatic generation)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view contracts (scope will filter)
  end

  def show?
    true  # All authenticated users can view contract details
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create contracts (automatic)
  end

  def update?
    admin?  # Only admin can update contracts
  end

  def destroy?
    admin?  # Only admin can delete contracts
  end

  # Digital signature actions
  def signature?
    show?  # If you can view the contract, you can access signature page
  end

  def save_signature?
    # Vendedor can sign contracts for loans they created
    # Admin can sign any contract
    admin? || (vendedor? && record.loan.present? && record.loan.user == user)
  end

  def success?
    show?  # Confirmation page after signature
  end

  def download?
    show?  # PDF download permission
  end

  def edit?
    admin?  # Only admin can edit QR codes
  end

  def update_qr_code?
    admin?  # Only admin can upload QR codes
  end

  def download_qr_code?
    show?  # Anyone with view access can download QR code
  end

  # Scope: Filter contracts based on role
  # - Admin: All contracts
  # - Supervisor: All contracts (NOT branch-limited)
  # - Vendedor: Contracts for loans in their branch
  class Scope < Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      elsif user&.vendedor?
        # Vendedor sees contracts for loans in their branch
        scope.joins(:loan).where(loans: { branch_number: user.branch_number })
      else
        scope.none
      end
    end
  end
end
