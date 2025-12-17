# frozen_string_literal: true

class AuditLogPolicy < ApplicationPolicy
  # Audit Log policies based on MOVICUOTAS permission matrix:
  # - View audit logs: Admin only
  # - Create/Update/Delete: Not allowed via controllers (created automatically via log methods)

  # Default CRUD actions (override as needed):
  def index?
    admin?  # Only admin can view audit logs
  end

  def show?
    admin?  # Only admin can view audit log details
  end

  def create?
    false  # Audit logs are created automatically via log methods, not via controllers
  end

  def update?
    false  # Audit logs cannot be updated
  end

  def destroy?
    false  # Audit logs cannot be deleted (preserve audit trail)
  end

  # Scope: Only admin can see audit logs
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
