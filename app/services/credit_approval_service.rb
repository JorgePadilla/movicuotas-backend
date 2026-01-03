# frozen_string_literal: true

class CreditApprovalService
  # Business rules for credit approval
  MINIMUM_AGE = 21
  MAXIMUM_AGE = 60

  # Approved amount ranges based on salary (used for calculating credit limit)
  APPROVED_AMOUNT_RANGES = {
    less_than_10000: 5000..8000,
    range_10000_20000: 8000..12000,
    range_20000_30000: 12000..18000,
    range_30000_40000: 18000..25000,
    more_than_40000: 25000..35000
  }.freeze

  # Mapping from old form values to correct enum values (for backward compatibility)
  SALARY_RANGE_VALUE_MAPPING = {
    "range_10000_20000" => "10000_20000",
    "range_20000_30000" => "20000_30000",
    "range_30000_40000" => "30000_40000"
    # "less_than_10000" and "more_than_40000" already match enum values
  }.freeze

  def initialize(credit_application, evaluator = nil)
    @credit_application = credit_application
    @evaluator = evaluator  # User who is approving (admin) or nil for auto-approval
  end

  # Main entry point: evaluate application and approve/reject
  def evaluate_and_approve
    return { approved: false, reason: "La solicitud ya ha sido procesada." } unless @credit_application.pending?

    validation_result = validate_application
    return validation_result unless validation_result[:approved]

    # Determine approval based on business rules
    if should_approve?
      approve_application
    else
      reject_application
    end
  end

  private

  # Validate basic requirements
  def validate_application
    Rails.logger.info "validate_application starting for credit application #{@credit_application.id}"
    # Check customer age (21-60 years for credit eligibility)
    customer_age = @credit_application.customer.age.to_i
    unless customer_age >= MINIMUM_AGE
      return { approved: false, reason: "El cliente debe tener al menos #{MINIMUM_AGE} años para obtener crédito (edad actual: #{customer_age} años)." }
    end

    unless customer_age <= MAXIMUM_AGE
      return { approved: false, reason: "El cliente no puede tener más de #{MAXIMUM_AGE} años para obtener crédito (edad actual: #{customer_age} años)." }
    end

    # Check required photos
    unless @credit_application.can_be_processed?
      return { approved: false, reason: "Faltan fotografías de identificación requeridas." }
    end

    # Employment status and salary range are NOT validated - all customers are approved
    # regardless of their employment situation

    # All validations passed
    { approved: true }
  end

  # Business logic decision - deterministic based on clear rules
  def should_approve?
    # If validation passed, approve. No random rejections.
    # All business rules are checked in validate_application method.
    true
  end

  def approve_application
    # Calculate approved amount based on salary range
    approved_amount = calculate_approved_amount

    @credit_application.approve!(approved_amount, @evaluator)

    # Log approval
    if @evaluator.nil?
      AuditLog.create!(
        user_id: nil,
        action: "credit_application_auto_approved",
        resource_type: "CreditApplication",
        resource_id: @credit_application.id,
        change_details: {
          status: [ "pending", "approved" ],
          approved_amount: [ nil, approved_amount ]
        }
      )
    end

    { approved: true, amount: approved_amount }
  end

  def reject_application
    rejection_reason = select_rejection_reason

    @credit_application.reject!(rejection_reason, @evaluator)

    # Log rejection
    if @evaluator.nil?
      AuditLog.create!(
        user_id: nil,
        action: "credit_application_auto_rejected",
        resource_type: "CreditApplication",
        resource_id: @credit_application.id,
        change_details: {
          status: [ "pending", "rejected" ],
          rejection_reason: [ nil, rejection_reason ]
        }
      )
    end

    { approved: false, reason: rejection_reason }
  end

  def calculate_approved_amount
    raw_value = @credit_application.salary_range
    return rand(5000..10000) unless raw_value.present?

    # Normalize value (map old form values to correct enum values)
    normalized_value = SALARY_RANGE_VALUE_MAPPING[raw_value] || raw_value

    # Get the enum key (symbol) from the normalized string value
    range_key = CreditApplication.salary_ranges.key(normalized_value)&.to_sym
    amount_range = APPROVED_AMOUNT_RANGES[range_key] || (5000..10000)

    # Random amount within range (in real system, would be based on credit score)
    rand(amount_range.begin..amount_range.end)
  end

  def select_rejection_reason
    reasons = [
      "Perfil crediticio no cumple con los requisitos mínimos.",
      "Historial crediticio insuficiente.",
      "Capacidad de pago no adecuada según el perfil ingresado.",
      "Información proporcionada requiere verificación adicional.",
      "Sistema de scoring no alcanzó el puntaje mínimo requerido."
    ]
    reasons.sample
  end
end
