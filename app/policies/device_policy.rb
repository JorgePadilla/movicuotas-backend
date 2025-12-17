# frozen_string_literal: true

class DevicePolicy < ApplicationPolicy
  # Device management policies based on MOVICUOTAS permission matrix:
  # - View devices: Admin (all), Vendedor (all), Cobrador (overdue only)
  # - Assign device: Admin and Vendedor
  # - Block device (MDM): Admin and Cobrador
  # - Unblock device: Admin only
  # - Delete device: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view devices (scope will filter for cobrador)
  end

  def show?
    true  # All authenticated users can view device details
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create devices
  end

  def update?
    admin? || vendedor?  # Admin and Vendedor can update devices
  end

  def destroy?
    admin?  # Only admin can delete devices
  end

  # Custom actions
  def assign?
    admin? || vendedor?  # Admin and Vendedor can assign devices
  end

  def lock?
    admin? || cobrador?  # Admin and Cobrador can block devices via MDM
  end

  def unlock?
    admin?  # Only admin can unblock devices
  end

  # Scope: Filter devices based on role
  # - Admin: All devices
  # - Vendedor: All devices
  # - Cobrador: Only devices with overdue installments (to be implemented later)
  class Scope < Scope
    def resolve
      if user&.admin? || user&.vendedor?
        scope.all
      elsif user&.cobrador?
        # TODO: Implement filtering for overdue devices only
        # scope.joins(loan: :installments).where(installments: { status: 'overdue' }).distinct
        scope.all  # Temporary: show all devices (will be filtered in controller)
      else
        scope.none
      end
    end
  end
end