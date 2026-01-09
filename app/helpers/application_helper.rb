module ApplicationHelper
  # Translation helpers for Spanish UI
  VERIFICATION_STATUS_ES = {
    "pending" => "Pendiente",
    "verified" => "Verificado",
    "rejected" => "Rechazado"
  }.freeze

  PAYMENT_METHOD_ES = {
    "cash" => "Efectivo",
    "transfer" => "Transferencia",
    "card" => "Tarjeta",
    "other" => "Otro"
  }.freeze

  LOAN_STATUS_ES = {
    "active" => "Activo",
    "paid" => "Pagado",
    "completed" => "Completado",
    "defaulted" => "En mora",
    "cancelled" => "Cancelado"
  }.freeze

  INSTALLMENT_STATUS_ES = {
    "pending" => "Pendiente",
    "paid" => "Pagado",
    "overdue" => "Vencido",
    "partial" => "Parcial"
  }.freeze

  CUSTOMER_STATUS_ES = {
    "active" => "Activo",
    "suspended" => "Suspendido",
    "blocked" => "Bloqueado"
  }.freeze

  ROLE_ES = {
    "admin" => "Administrador",
    "supervisor" => "Supervisor",
    "vendedor" => "Vendedor"
  }.freeze

  GENDER_ES = {
    "male" => "Masculino",
    "female" => "Femenino",
    "other" => "Otro"
  }.freeze

  def verification_status_es(status)
    VERIFICATION_STATUS_ES[status.to_s] || status.to_s.titleize
  end

  def payment_method_es(method)
    PAYMENT_METHOD_ES[method.to_s] || method.to_s.titleize
  end

  def loan_status_es(status)
    LOAN_STATUS_ES[status.to_s] || status.to_s.titleize
  end

  def installment_status_es(status)
    INSTALLMENT_STATUS_ES[status.to_s] || status.to_s.titleize
  end

  def customer_status_es(status)
    CUSTOMER_STATUS_ES[status.to_s] || status.to_s.titleize
  end

  def role_es(role)
    ROLE_ES[role.to_s] || role.to_s.titleize
  end

  def gender_es(gender)
    GENDER_ES[gender.to_s] || gender.to_s.titleize
  end

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
