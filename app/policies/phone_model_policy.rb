# frozen_string_literal: true

class PhoneModelPolicy < ApplicationPolicy
  # Phone Model policies (catalog of available phones)
  # - View phone models: Admin, Supervisor (for selection), Cobrador (if needed)
  # - Create/Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    true  # All authenticated users can view phone catalog
  end

  def show?
    true  # All authenticated users can view phone details
  end

  def create?
    admin?  # Only admin can create phone models
  end

  def update?
    admin?  # Only admin can update phone models
  end

  def destroy?
    admin?  # Only admin can delete phone models
  end

  # Scope: All authenticated users can see all phone models
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
