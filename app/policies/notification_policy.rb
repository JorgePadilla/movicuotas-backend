# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  # Notification management policies
  # Notifications are sent to customers for payment reminders, device locks, etc.
  # - View notifications: Admin only (or users see their own notifications)
  # - Create notifications: Admin and Supervisor (for customer communication)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    admin?  # Only admin can view all notifications
  end

  def show?
    admin?  # Only admin can view notification details
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can create notifications
  end

  def update?
    admin?  # Only admin can update notifications
  end

  def destroy?
    admin?  # Only admin can delete notifications
  end

  # Scope: Filter notifications based on role
  # - Admin: All notifications
  # - Other roles: No access
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none  # Only admin can see notifications
      end
    end
  end
end
