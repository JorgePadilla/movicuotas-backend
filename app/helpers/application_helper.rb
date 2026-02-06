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
    "draft" => "Borrador",
    "active" => "Activo",
    "paid" => "Pagado",
    "completed" => "Completado",
    "overdue" => "En Mora",
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
    "master" => "Master",
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

  def sortable_header(column, title, opts = {})
    is_current = @sort_column == column.to_s
    direction = if is_current && @sort_direction == "asc"
      "desc"
    else
      "asc"
    end

    arrow = if is_current
      @sort_direction == "asc" ? " \u25B2" : " \u25BC"
    else
      ""
    end

    css = "px-#{opts[:px] || 3} py-3 text-left text-xs font-medium uppercase tracking-wider cursor-pointer hover:text-[#125282] select-none group"
    css += if is_current
      " text-[#125282]"
    else
      " text-gray-500"
    end

    merged_params = request.query_parameters.except("page").merge(sort: column, direction: direction)

    content_tag(:th, scope: "col", class: css) do
      link_to(url_for(merged_params), class: "flex items-center gap-1 no-underline hover:no-underline") do
        concat(title)
        if is_current
          concat(content_tag(:span, arrow, class: "text-[10px]"))
        else
          concat(content_tag(:span, " \u25B2\u25BC", class: "text-[10px] text-gray-300 group-hover:text-gray-400"))
        end
      end
    end
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
