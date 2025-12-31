# app/services/loan_finalization_service.rb
class LoanFinalizationService
  # This service finalizes a loan after all previous steps are completed.
  # It creates the Loan record, generates installments, assigns device,
  # and updates all related records in a single atomic transaction.
  #
  # Inputs:
  # - credit_application: Approved CreditApplication instance
  # - device: Selected Device instance (with IMEI, phone_model, etc.)
  # - loan_attributes: Hash with loan parameters from payment calculator:
  #     total_amount, down_payment_percentage, number_of_installments, interest_rate
  # - contract: Contract instance (with signature attached)
  # - current_user: User creating the loan (vendor)
  #
  # Output: Completed Loan instance with all installments created
  #
  # Critical validations:
  # 1. Customer has NO other active loans system-wide (should be validated in Step 2)
  # 2. Device IMEI is unique system-wide (validated in Device model)
  # 3. Phone price <= approved_amount (validated in Loan model)
  # 4. All prerequisites completed (credit approved, device selected, contract signed)
  #
  # Contract number format: {branch}-{date}-{sequence}
  # Example: "S01-2025-12-18-000001"

  def initialize(credit_application:, device:, loan_attributes:, contract:, current_user:)
    @credit_application = credit_application
    @device = device
    @loan_attributes = loan_attributes
    @contract = contract
    @current_user = current_user
    @customer = credit_application.customer
  end

  def finalize!
    validate_prerequisites!

    ActiveRecord::Base.transaction do
      # 1. Create Loan record
      loan = create_loan

      # 2. Generate bi-weekly installments
      create_installments(loan)

      # 3. Assign device to loan
      assign_device_to_loan(loan)

      # 4. Link contract to loan
      link_contract_to_loan(loan)

      # 5. Update credit application status to finalized
      mark_credit_application_as_finalized

      # 6. Create audit log
      create_audit_log(loan)

      # Return the completed loan
      loan
    end
  rescue ActiveRecord::RecordInvalid => e
    raise LoanFinalizationError, "Error al finalizar el crédito: #{e.message}"
  rescue StandardError => e
    raise LoanFinalizationError, "Error inesperado: #{e.message}"
  end

  private

  def validate_prerequisites!
    # Validate credit application is approved
    unless @credit_application.approved?
      raise LoanFinalizationError, "La solicitud de crédito no está aprobada"
    end

    # Validate device is available (not assigned to another loan)
    if @device.loan.present?
      raise LoanFinalizationError, "El dispositivo ya está asignado a otro crédito"
    end

    # Validate contract is signed
    unless @contract.signed?
      raise LoanFinalizationError, "El contrato no está firmado"
    end

    # Validate customer has no other active loans (system-wide check)
    if @customer.loans.active.exists?
      raise LoanFinalizationError, "El cliente ya tiene un crédito activo en el sistema"
    end

    # Validate approved amount covers total amount
    if @loan_attributes[:total_amount] > @credit_application.approved_amount
      raise LoanFinalizationError, "El monto total excede el monto aprobado"
    end

    # Validate down payment percentage is allowed (30%, 40%, 50%)
    unless [ 30, 40, 50 ].include?(@loan_attributes[:down_payment_percentage])
      raise LoanFinalizationError, "Porcentaje de enganche inválido. Debe ser 30%, 40% o 50%"
    end

    # Validate number of installments is allowed (6, 8, 12)
    unless [ 6, 8, 12 ].include?(@loan_attributes[:number_of_installments])
      raise LoanFinalizationError, "Número de cuotas inválido. Debe ser 6, 8 o 12"
    end
  end

  def create_loan
    # Build loan from credit application and loan attributes
    loan = Loan.new(
      customer: @customer,
      user: @current_user,
      branch_number: @current_user.branch_number || "S01", # Default branch if not set
      total_amount: @loan_attributes[:total_amount],
      approved_amount: @credit_application.approved_amount,
      down_payment_percentage: @loan_attributes[:down_payment_percentage],
      number_of_installments: @loan_attributes[:number_of_installments],
      interest_rate: @loan_attributes[:interest_rate] || 12.0, # Default annual interest rate
      start_date: Date.today,
      status: :active
    )

    # Calculate amounts (down_payment_amount, financed_amount) via callbacks
    loan.save!
    loan
  end

  def create_installments(loan)
    # Calculate bi-weekly installment amount
    installment_amount = calculate_biweekly_installment_amount(loan)

    # Create installments for each bi-weekly period
    (1..loan.number_of_installments).each do |installment_number|
      due_date = loan.start_date + (installment_number * 14).days

      Installment.create!(
        loan: loan,
        installment_number: installment_number,
        due_date: due_date,
        amount: installment_amount,
        status: :pending
      )
    end
  end

  def calculate_biweekly_installment_amount(loan)
    # Calculate bi-weekly installment using standard formula
    # P = financed_amount
    # r = bi-weekly interest rate (annual_rate / 26)
    # n = number_of_installments
    # Installment = P * [r(1+r)^n] / [(1+r)^n - 1]

    financed_amount = loan.financed_amount
    annual_interest_rate = loan.interest_rate / 100.0  # Convert percentage to decimal
    biweekly_interest_rate = annual_interest_rate / 26.0  # 26 bi-weekly periods per year
    n = loan.number_of_installments

    # Handle zero interest rate (simple division)
    if biweekly_interest_rate.zero?
      return (financed_amount / n).ceil
    end

    # Calculate using annuity formula
    numerator = biweekly_interest_rate * (1 + biweekly_interest_rate) ** n
    denominator = (1 + biweekly_interest_rate) ** n - 1
    installment = financed_amount * (numerator / denominator)

    installment.ceil
  end

  def assign_device_to_loan(loan)
    @device.update!(
      loan: loan,
      # Status is already managed by lock_status, no need for additional status
    )
  end

  def link_contract_to_loan(loan)
    @contract.update!(loan: loan)
  end

  def mark_credit_application_as_finalized
    @credit_application.update!(status: :finalized) if CreditApplication.statuses.key?(:finalized)
    # If finalized status doesn't exist, we could add a boolean flag or leave as approved
  end

  def create_audit_log(loan)
    AuditLog.create!(
      user: @current_user,
      action: "loan_finalized",
      resource: loan,
      changes: {
        contract_number: loan.contract_number,
        total_amount: loan.total_amount,
        customer_id: loan.customer_id,
        device_imei: @device.imei
      }
    )
  end
end

# Custom error class for loan finalization errors
class LoanFinalizationError < StandardError
end
