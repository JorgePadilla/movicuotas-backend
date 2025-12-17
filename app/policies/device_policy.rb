# frozen_string_literal: true

class DevicePolicy < ApplicationPolicy
  def index?
    true # Everyone can view devices (with scopes limiting access)
  end

  def show?
    true # Everyone can view device details (with scopes limiting access)
  end

  def create?
    admin? || vendedor? # Only admin and vendedor can create devices
  end

  def update?
    admin? || vendedor? # Only admin and vendedor can update devices
  end

  def destroy?
    admin? # Only admin can delete devices
  end

  def lock?
    admin? || cobrador? # Cobrador CAN block devices
  end

  def unlock?
    admin? # Only admin can unlock
  end

  # Scope for device access
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.vendedor?
        scope.where(branch_number: user.branch_number)
      elsif user.cobrador?
        # Cobradores can only see devices with overdue loans
        scope.joins(loan: :installments)
             .where(installments: { status: 'overdue' })
             .distinct
      else
        scope.none
      end
    end
  end
end