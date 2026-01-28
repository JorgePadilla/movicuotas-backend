# frozen_string_literal: true

class DevicePolicy < ApplicationPolicy
  # Device management policies based on MOVICUOTAS permission matrix:
  #
  # Roles:
  # - Admin: Full access (create, edit, delete, block, unblock)
  # - Supervisor: View all, block devices via MDM (cannot unblock)
  # - Vendedor: View all, assign devices only (cannot block/unblock)

  def index?
    true  # All authenticated users can view devices
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

  # Assign device to customer - Admin and Vendedor
  def assign?
    admin? || vendedor?
  end

  # Block device via MDM - Admin and Supervisor
  def lock?
    admin? || supervisor?
  end

  # Unblock device - Admin and Supervisor
  def unlock?
    admin? || supervisor?
  end

  # Reset device activation - Admin only
  def reset_activation?
    admin?
  end

  # Scope: All roles can see all devices
  # - Admin: All devices
  # - Supervisor: All devices (for blocking purposes)
  # - Vendedor: All devices (for assignment purposes)
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
