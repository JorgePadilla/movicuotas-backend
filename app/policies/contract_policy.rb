# frozen_string_literal: true

class ContractPolicy < ApplicationPolicy
  # Contract policies (digital contracts with customer signatures)
  # - View contracts: Admin (all), Vendedor (own), Cobrador (all read-only)
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

  # Scope: Filter contracts based on role
  # - Admin: All contracts
  # - Vendedor: Contracts for loans they created
  # - Cobrador: All contracts (read-only access)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.cobrador?
        scope.all
      elsif user&.vendedor?
        # Assuming contract belongs to loan, and loan belongs to user (vendedor)
        scope.joins(loan: :user).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end
