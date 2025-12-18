# frozen_string_literal: true

class CreditApprovalService
  # Business rules for credit approval
  MINIMUM_AGE = 18
  MINIMUM_SALARY_RANGE = :range_10000_20000  # At least L. 10,000 - L. 20,000
  APPROVAL_RATE = 0.85  # 85% of applications are approved (for simulation)
  APPROVED_AMOUNT_RANGES = {
    less_than_10000: 5000..8000,
    range_10000_20000: 8000..12000,
    range_20000_30000: 12000..18000,
    range_30000_40000: 18000..25000,
    more_than_40000: 25000..35000
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
    # Check customer age
    unless @credit_application.customer.adult?
      return { approved: false, reason: "El cliente debe ser mayor de edad (18+ años)." }
    end

    # Check required photos
    unless @credit_application.can_be_processed?
      return { approved: false, reason: "Faltan fotografías de identificación requeridas." }
    end

    # Check employment status (must be employed, self_employed, or retired with pension)
    unless valid_employment_status?
      return { approved: false, reason: "La situación laboral no cumple con los requisitos mínimos." }
    end

    # Check salary range
    unless valid_salary_range?
      return { approved: false, reason: "El rango salarial no cumple con los requisitos mínimos." }
    end

    # All validations passed
    { approved: true }
  end

  def valid_employment_status?
    # Employed, self-employed, or retired (assuming pension) are acceptable
    acceptable_statuses = %w[employed self_employed retired]
    acceptable_statuses.include?(@credit_application.employment_status)
  end

  def valid_salary_range?
    # Convert salary_range to comparable value
    salary_ranges = CreditApplication.salary_ranges.keys
    current_index = salary_ranges.index(@credit_application.salary_range.to_s)
    minimum_index = salary_ranges.index(MINIMUM_SALARY_RANGE.to_s)

    current_index && minimum_index && current_index >= minimum_index
  end

  # Business logic decision (simulated)
  def should_approve?
    # In real system, this would involve credit scoring, external APIs, etc.
    # For now, use a combination of factors with randomness for simulation

    # Base approval probability
    probability = APPROVAL_RATE

    # Adjust based on salary range (higher salary = higher probability)
    salary_factor = case @credit_application.salary_range
                    when "less_than_10000" then 0.7
                    when "range_10000_20000" then 0.8
                    when "range_20000_30000" then 0.9
                    when "range_30000_40000" then 0.95
                    when "more_than_40000" then 1.0
                    else 0.8
                    end

    # Adjust based on employment status
    employment_factor = case @credit_application.employment_status
                        when "employed" then 1.0
                        when "self_employed" then 0.9
                        when "retired" then 0.8
                        else 0.5
                        end

    final_probability = probability * salary_factor * employment_factor
    rand <= final_probability
  end

  def approve_application
    # Calculate approved amount based on salary range
    approved_amount = calculate_approved_amount

    @credit_application.approve!(approved_amount, @evaluator)

    # Log approval
    AuditLog.create!(
      user: @evaluator,
      action: "credit_application_auto_approved",
      resource: @credit_application,
      changes: {
        status: ["pending", "approved"],
        approved_amount: [nil, approved_amount]
      }
    ) if @evaluator.nil?  # Only log if auto-approved (no human evaluator)

    { approved: true, amount: approved_amount }
  end

  def reject_application
    rejection_reason = select_rejection_reason

    @credit_application.reject!(rejection_reason, @evaluator)

    # Log rejection
    AuditLog.create!(
      user: @evaluator,
      action: "credit_application_auto_rejected",
      resource: @credit_application,
      changes: {
        status: ["pending", "rejected"],
        rejection_reason: [nil, rejection_reason]
      }
    ) if @evaluator.nil?

    { approved: false, reason: rejection_reason }
  end

  def calculate_approved_amount
    range_key = @credit_application.salary_range.to_sym
    amount_range = APPROVED_AMOUNT_RANGES[range_key] || 5000..10000

    # Random amount within range (in real system, would be based on credit score)
    rand(amount_range)
  end

  def select_rejection_reason
    reasons = [
      "Perfil crediticio no cumple con los requisitos mínimos.",
      "Historial crediticio insuficiente.",
      "Capacidad de pago no adecuada para el monto solicitado.",
      "Información proporcionada requiere verificación adicional.",
      "Sistema de scoring no alcanzó el puntaje mínimo requerido."
    ]
    reasons.sample
  end
end