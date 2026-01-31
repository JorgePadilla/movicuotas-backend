# frozen_string_literal: true

class MdmBlueprintPolicy < ApplicationPolicy
  # MDM Blueprint policies (QR codes for device MDM configuration)
  # - View blueprints: Admin and Supervisor
  # - Create blueprints: Admin and Supervisor (automatic generation)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    admin? || supervisor?  # Admin and Supervisor can view blueprints
  end

  def show?
    vendedor? || admin? || supervisor?  # Vendedor needs access for Step 16 (QR code)
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can create blueprints
  end

  def update?
    admin?  # Only admin can update blueprints
  end

  def destroy?
    admin?  # Only admin can delete blueprints
  end

  # Scope: Filter blueprints based on role
  # - Admin: All blueprints
  # - Supervisor: Blueprints for devices they assigned
  class Scope < Scope
    def resolve
      if user&.admin? || user&.master?
        scope.all
      elsif user&.supervisor?
        # Assuming mdm_blueprint belongs to device, and device belongs to loan, and loan belongs to user (supervisor)
        scope.joins(device: { loan: :user }).where(loans: { user: user })
      else
        scope.none
      end
    end
  end
end
