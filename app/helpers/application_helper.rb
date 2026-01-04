module ApplicationHelper
  # Determines the resume path for a pending credit application based on its progress
  def resume_path_for(credit_application)
    return edit_vendor_credit_application_path(credit_application) unless credit_application

    # Check progress and return appropriate path
    if !credit_application.id_front_image.attached? ||
       !credit_application.id_back_image.attached? ||
       !credit_application.facial_verification_image.attached?
      # Missing photos - go to photos step
      photos_vendor_credit_application_path(credit_application)
    elsif !credit_application.otp_verified?
      # OTP not verified - go to verification step
      verify_otp_vendor_credit_application_path(credit_application)
    elsif credit_application.employment_status.blank? || credit_application.salary_range.blank?
      # Missing employment data - go to employment step
      employment_vendor_credit_application_path(credit_application)
    else
      # All data complete - go to summary
      summary_vendor_credit_application_path(credit_application)
    end
  end
end
