# frozen_string_literal: true

class CreditApplicationPolicy < ApplicationPolicy
  # Credit Application policies based on MOVICUOTAS permission matrix:
  # - Create credit application: Admin and Supervisor
  # - Approve credit: Admin only (automatic for supervisor submissions)
  # - View applications: Admin (all), Supervisor (own only)
  # - Cobrador: Cannot access credit applications

  # Default CRUD actions (override as needed):
  def index?
    admin? || supervisor?  # Admin and Supervisor can view applications
  end

  def show?
    admin? || (supervisor? && own_application?)
  end

  def create?
    admin? || supervisor?  # Admin and Supervisor can create applications
  end

  def update?
    admin? || (supervisor? && own_application?)  # Admin and Supervisor (own only) can update
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
    admin?  # Only admin can manually approve applications (supervisor submissions auto-approved)
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

  def confirmation?
    show?  # Read-only view of confirmation step
  end

  # OTP verification actions
  def verify_otp?
    show?  # View OTP verification page
  end

  def send_otp?
    update?  # Sending OTP modifies the application
  end

  def submit_otp_verification?
    update?  # Verifying OTP modifies the application
  end

  def resend_otp?
    update?  # Resending OTP modifies the application
  end

  # Scope: Filter applications based on role
  # - Admin: All applications
  # - Supervisor: Only applications they created
  # - Cobrador: No access
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.supervisor?
        # Assuming credit_application has a `vendor` association with the supervisor who created it
        scope.where(vendor: user)
      else
        scope.none
      end
    end
  end

  private

  def own_application?
    # Assuming credit_application has a `vendor` association with the supervisor who created it
    record.vendor == user
  end
end
