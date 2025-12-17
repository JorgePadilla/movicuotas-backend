# Base policy class
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Default policy: only admins can index
  def index?
    user&.admin?
  end

  # Default policy: only admins can show
  def show?
    user&.admin?
  end

  # Default policy: only admins can create
  def create?
    user&.admin?
  end

  # Default policy: only admins can update
  def update?
    user&.admin?
  end

  # Default policy: only admins can destroy
  def destroy?
    user&.admin?
  end

  # Scope class for listing records
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end