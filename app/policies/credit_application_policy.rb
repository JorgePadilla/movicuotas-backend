# frozen_string_literal: true

class CreditApplicationPolicy < ApplicationPolicy
  # Credit Application policies based on MOVICUOTAS permission matrix:
  # - Create credit application: Admin and Vendedor
  # - Approve credit: Admin only (automatic for vendedor submissions)
  # - View applications: Admin (all), Vendedor (own only)
  # - Cobrador: Cannot access credit applications

  # Default CRUD actions (override as needed):
  def index?
    admin? || vendedor?  # Admin and Vendedor can view applications
  end

  def show?
    admin? || (vendedor? && own_application?)
  end

  def create?
    admin? || vendedor?  # Admin and Vendedor can create applications
  end

  def update?
    admin? || (vendedor? && own_application?)  # Admin and Vendedor (own only) can update
  end

  def destroy?
    admin?  # Only admin can delete applications
  end

  def edit?
    update?  # Same permissions as update
  end

  def new?
    create?  # Same permissions as create
  end

  # Custom actions
  def approve?
    admin?  # Only admin can manually approve applications (vendedor submissions auto-approved)
  end

  # Step actions for vendor workflow
  def photos?
    show?  # Read-only view of photos step
  end

  def update_photos?
    update?  # Modifying photos
  end

  def employment?
    show?  # Read-only view of employment step
  end

  def update_employment?
    update?  # Modifying employment data
  end

  def summary?
    show?  # Read-only view of summary
  end

  def submit?
    update?  # Submitting application changes status
  end

  def approved?
    show?  # Read-only view of approved page
  end

  def rejected?
    show?  # Read-only view of rejected page
  end

  # Scope: Filter applications based on role
  # - Admin: All applications
  # - Vendedor: Only applications they created
  # - Cobrador: No access
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.vendedor?
        # Assuming credit_application has a `vendor` association with the vendedor who created it
        scope.where(vendor: user)
      else
        scope.none
      end
    end
  end

  private

  def own_application?
    # Assuming credit_application has a `vendor` association with the vendedor who created it
    record.vendor == user
  end
end
