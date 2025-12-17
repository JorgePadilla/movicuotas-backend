# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  # Notification management policies
  # Notifications are sent to customers for payment reminders, device locks, etc.
  # - View notifications: Admin only (or users see their own notifications)
  # - Create notifications: Admin and Vendedor (for customer communication)
  # - Update/Delete: Admin only

  # Default CRUD actions (override as needed):
  def index?
    admin?  # Only admin can view all notifications
  end

  def show?
    admin? || own_notification?
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create notifications
  end

  def update?
    admin?  # Only admin can update notifications
  end

  def destroy?
    admin?  # Only admin can delete notifications
  end

  # Scope: Filter notifications based on role
  # - Admin: All notifications
  # - Vendedor: Notifications they created (or for their customers)
  # - Users: Only their own notifications (if applicable)
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.vendedor?
        # Assuming notification has a `user` association with the creator
        scope.where(user: user)
      else
        scope.none
      end
    end
  end

  private

  def own_notification?
    # Assuming notification has a `user` association with the creator
    record.user == user
  end
end
