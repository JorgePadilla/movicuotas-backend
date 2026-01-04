# frozen_string_literal: true

class ContractPolicy < ApplicationPolicy
  # Contract policies (digital contracts with customer signatures)
  # - View contracts: Admin (all), Supervisor (own), Cobrador (all read-only)
  # - Create contracts: Admin and Supervisor (automatic generation)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view contracts (scope will filter)
  end

  def show?
    true  # All authenticated users can view contract details
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can create contracts (automatic)
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
    # Supervisor can sign contracts for loans they created
    # Admin can sign any contract
    admin? || (supervisor? && record.loan.present? && record.loan.user == user)
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
  # - Supervisor: Contracts for loans they created
  # - Cobrador: All contracts (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.supervisor?
        # Assuming contract belongs to loan, and loan belongs to user (supervisor)
        scope.joins(loan: :user).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end
