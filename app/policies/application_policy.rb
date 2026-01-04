# frozen_string_literal: true

# Base policy class for all Pundit policies
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Role helpers
  def admin?
    user&.admin?
  end

  def supervisor?
    user&.supervisor?
  end

  def cobrador?
    user&.cobrador?
  end

  # Default permissions based on MOVICUOTAS permission matrix
  # These defaults follow the most common pattern:
  # - Viewing (index, show): All authenticated users
  # - Creating/Updating: Admin and Supervisor (where applicable)
  # - Destroying: Admin only

  def index?
    user.present?  # All authenticated users can view lists
  end

  def show?
    user.present?  # All authenticated users can view details
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can create
  end

  def new?
    create?
  end

  def update?
    admin? || supervisor?  # Admin and Supervisor can update
  end

  def edit?
    update?
  end

  def destroy?
    admin?  # Only admin can destroy
  end

  # Scope base class - defaults to all records
  # Individual policies should override #resolve for scoping
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all  # Default: show all records (override in specific policies)
    end
  end
end
