# frozen_string_literal: true

class MdmBlueprintPolicy < ApplicationPolicy
  # MDM Blueprint policies (QR codes for device MDM configuration)
  # - View blueprints: Admin and Vendedor
  # - Create blueprints: Admin and Vendedor (automatic generation)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    admin? || vendedor?  # Admin and Vendedor can view blueprints
  end

  def show?
    admin? || vendedor?  # Admin and Vendedor can view blueprint details
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create blueprints
  end

  def update?
    admin?  # Only admin can update blueprints
  end

  def destroy?
    admin?  # Only admin can delete blueprints
  end

  # Scope: Filter blueprints based on role
  # - Admin: All blueprints
  # - Vendedor: Blueprints for devices they assigned
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.vendedor?
        # Assuming mdm_blueprint belongs to device, and device belongs to loan, and loan belongs to user (vendedor)
        scope.joins(device: { loan: :user }).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end