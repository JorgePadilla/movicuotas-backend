# frozen_string_literal: true

class DevicePolicy < ApplicationPolicy
  # Device management policies based on MOVICUOTAS permission matrix:
  # - View devices: Admin (all), Supervisor (all), Cobrador (overdue only)
  # - Assign device: Admin and Supervisor
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
    admin? || supervisor?  # Admin and Supervisor can create devices
  end

  def update?
    admin? || supervisor?  # Admin and Supervisor can update devices
  end

  def destroy?
    admin?  # Only admin can delete devices
  end

  # Custom actions
  def assign?
    admin? || supervisor?  # Admin and Supervisor can assign devices
  end

  def lock?
    admin? || cobrador?  # Admin and Cobrador can block devices via MDM
  end

  def unlock?
    admin?  # Only admin can unblock devices
  end

  # Scope: Filter devices based on role
  # - Admin: All devices
  # - Supervisor: All devices
  # - Cobrador: Only devices with overdue installments
  class Scope < Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      elsif user&.cobrador?
        # Cobradores can only see devices with overdue loans
        scope.joins(loan: :installments)
             .where(installments: { status: "overdue" })
             .distinct
      else
        scope.none
      end
    end
  end
end
