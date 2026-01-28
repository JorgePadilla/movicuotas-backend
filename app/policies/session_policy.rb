# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  # Session management policies
  # - Admin: Can view all sessions
  # - Users: Can only manage their own sessions (logout)

  def index?
    admin?
  end

  def show?
    admin? || owns_session?
  end

  def create?
    true  # Login is public
  end

  def destroy?
    admin? || owns_session?
  end

  def update?
    false  # Sessions cannot be updated
  end

  def edit?
    update?
  end

  # Scope: Admin and master see all, users see only their own sessions
  class Scope < Scope
    def resolve
      if user&.admin? || user&.master?
        scope.all
      elsif user.present?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end

  private

  def owns_session?
    record.user == user
  end
end
