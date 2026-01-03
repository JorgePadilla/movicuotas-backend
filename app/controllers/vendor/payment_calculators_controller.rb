# frozen_string_literal: true

module Vendor
  class PaymentCalculatorsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: [ :new, :calculate ]

    # Step 12: Payment Calculator
    # Display calculator form with down payment options and installment terms
    def new
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      # Get parameters from previous step (Step 11: Confirmation)
      # Phone price and approved amount should be passed via session or params
      @phone_price = params[:phone_price]&.to_f || session[:phone_price] || 0
      @approved_amount = params[:approved_amount]&.to_f || session[:approved_amount] || 0
      @credit_application_id = params[:credit_application_id] || session[:credit_application_id]

      # Validate phone price against approved amount
      if @phone_price > 0 && @approved_amount > 0 && @phone_price > @approved_amount
        flash[:alert] = "El precio del teléfono (L. #{@phone_price}) excede el monto aprobado (L. #{@approved_amount})"
        redirect_to vendor_customer_search_path and return
      end

      # Get customer date of birth for age validation
      @date_of_birth = fetch_date_of_birth
      unless @date_of_birth
        flash[:alert] = "No se pudo obtener la fecha de nacimiento del cliente. Verifique la solicitud de crédito."
        redirect_to vendor_customer_search_path and return
      end

      # Calculate customer age to determine default down payment
      @customer_age = calculate_customer_age(@date_of_birth)
      is_senior_customer = @customer_age && @customer_age >= 50 && @customer_age <= 60

      # Default calculator values
      # Senior customers (50-60 years) default to 40%, others to 30%
      default_down_payment = is_senior_customer ? 40 : 30
      @down_payment_percentage = params[:down_payment_percentage]&.to_i || default_down_payment

      # Ensure senior customers don't have 30% selected
      if is_senior_customer && @down_payment_percentage == 30
        @down_payment_percentage = 40
      end

      @number_of_installments = params[:number_of_installments]&.to_i || 6

      # Calculate initial installment amount
      @calculator = BiweeklyCalculatorService.new(
        phone_price: @phone_price,
        down_payment_percentage: @down_payment_percentage,
        number_of_installments: @number_of_installments,
        date_of_birth: @date_of_birth
      )

      @result = @calculator.calculate
    end

    # Calculate installment amount dynamically (Turbo Stream)
    # Called via AJAX/Turbo when user changes down payment or installment term
    def calculate
      Rails.logger.info "PaymentCalculator#calculate called with params: #{params.permit(:phone_price, :down_payment_percentage, :number_of_installments, :date_of_birth, :approved_amount, :credit_application_id).to_h}"
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      phone_price = params[:phone_price]&.to_f || 0
      down_payment_percentage = params[:down_payment_percentage]&.to_i || 30
      number_of_installments = params[:number_of_installments]&.to_i || 6
      date_of_birth = params[:date_of_birth].present? ? params[:date_of_birth] : fetch_date_of_birth

      unless date_of_birth
        return respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "calculator_errors",
              partial: "vendor/payment_calculators/errors",
              locals: { errors: [ "No se pudo obtener la fecha de nacimiento del cliente" ] }
            )
          end
          format.html do
            flash.now[:alert] = "No se pudo obtener la fecha de nacimiento del cliente"
            render :new
          end
        end
      end

      calculator = BiweeklyCalculatorService.new(
        phone_price: phone_price,
        down_payment_percentage: down_payment_percentage,
        number_of_installments: number_of_installments,
        date_of_birth: date_of_birth
      )

      result = calculator.calculate

      respond_to do |format|
        format.turbo_stream do
          if result[:success]
            render turbo_stream: turbo_stream.update(
              "calculator_results",
              partial: "vendor/payment_calculators/results",
              locals: { result: result }
            )
          else
            render turbo_stream: turbo_stream.update(
              "calculator_errors",
              partial: "vendor/payment_calculators/errors",
              locals: { errors: result[:errors] }
            )
          end
        end

        format.html do
          if result[:success]
            flash.now[:notice] = "Cálculo actualizado"
          else
            flash.now[:alert] = result[:errors].join(", ")
          end
          render :new
        end
      end
    end

    # Create loan with calculated installments (proceed to Step 13: Contract)
    def create
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      Rails.logger.info "PaymentCalculator#create called with params: #{params.permit(:phone_price, :approved_amount, :down_payment_percentage, :number_of_installments, :date_of_birth, :credit_application_id).to_h}"

      # Temporary implementation for contract feature testing
      # Will be replaced by LoanFinalizationService in phase2-vendor-loan-finalization
      loan = create_loan_from_calculator

      Rails.logger.info "Loan creation result: persisted=#{loan.persisted?}, errors=#{loan.errors.full_messages}, contract_number=#{loan.contract_number}"

      if loan.persisted?
        # Find or create contract for this loan
        contract = Contract.find_or_create_by!(loan: loan)

        Rails.logger.info "Contract found/created: id=#{contract.id}, loan_id=#{contract.loan_id}"
        flash[:notice] = "Préstamo creado exitosamente. Procediendo al contrato..."
        redirect_to vendor_contract_path(contract)
      else
        flash[:alert] = "Error al crear préstamo: #{loan.errors.full_messages.join(', ')}"
        redirect_to vendor_payment_calculator_path
      end
    end

    private

    # Create a loan based on calculator parameters (temporary implementation)
    def create_loan_from_calculator
      # Get parameters from form
      phone_price = params[:phone_price]&.to_f || session[:phone_price] || 0
      approved_amount = params[:approved_amount]&.to_f || session[:approved_amount] || 0
      down_payment_percentage = params[:down_payment_percentage]&.to_i || 30
      number_of_installments = params[:number_of_installments]&.to_i || 6
      date_of_birth = params[:date_of_birth] || fetch_date_of_birth
      Rails.logger.info "date_of_birth value: #{date_of_birth.inspect}"
      if date_of_birth.blank?
        return Loan.new.tap { |l| l.errors.add(:base, "Fecha de nacimiento del cliente no disponible. Por favor, verifica la solicitud de crédito.") }
      end
      credit_application_id = params[:credit_application_id] || session[:credit_application_id]

      Rails.logger.info "create_loan_from_calculator: phone_price=#{phone_price}, approved_amount=#{approved_amount}, down_payment_percentage=#{down_payment_percentage}, number_of_installments=#{number_of_installments}, credit_application_id=#{credit_application_id}"

      # Get customer from credit application
      credit_application = CreditApplication.find_by(id: credit_application_id) if credit_application_id.present?
      Rails.logger.info "Credit application lookup: id=#{credit_application_id}, found=#{credit_application.present?}, customer_id=#{credit_application&.customer&.id}"
      customer = credit_application&.customer || Customer.first # Fallback for testing

      if customer.nil?
        Rails.logger.error "No customer found for credit_application_id=#{credit_application_id} and no Customer.first exists"
        return Loan.new.tap { |l| l.errors.add(:base, "No se pudo encontrar el cliente. Por favor, verifica la solicitud de crédito.") }
      end

      Rails.logger.info "Using customer: id=#{customer.id}, name=#{customer.full_name || 'N/A'}"

      # Validate phone price against approved amount
      if phone_price > approved_amount
        return Loan.new.tap { |l| l.errors.add(:base, "El precio del teléfono excede el monto aprobado") }
      end

      # Calculate using BiweeklyCalculatorService
      calculator = BiweeklyCalculatorService.new(
        phone_price: phone_price,
        down_payment_percentage: down_payment_percentage,
        number_of_installments: number_of_installments,
        date_of_birth: date_of_birth
      )

      result = calculator.calculate
      unless result[:success]
        loan = Loan.new
        result[:errors].each { |error| loan.errors.add(:base, error) }
        return loan
      end

      # Generate contract number (will be auto-generated by Loan model)
      branch_number = current_user.branch_number || 'S01'
      start_date = Date.today

      # First, try to find an existing draft loan for this customer created today
      existing_loan = find_existing_draft_loan(customer, phone_price, approved_amount, credit_application_id)
      if existing_loan.present?
        # Ensure device exists for existing loan (may have been missed in previous flow)
        if existing_loan.device.nil? && credit_application && credit_application.selected_phone_model_id && credit_application.selected_imei
          Rails.logger.info "Existing loan #{existing_loan.id} has no device, creating from credit application #{credit_application.id}"
          create_device_for_loan(existing_loan, credit_application)
        end
        return existing_loan
      end

      # Create new loan
      loan = Loan.new(
        customer: customer,
        user: current_user, # Creator (vendor)
        branch_number: branch_number,
        status: 'draft', # Will become active after contract signature
        total_amount: phone_price,
        approved_amount: approved_amount,
        down_payment_percentage: down_payment_percentage,
        down_payment_amount: result[:down_payment_amount],
        financed_amount: result[:financed_amount],
        interest_rate: result[:bi_weekly_rate_percentage], # Store as percentage
        number_of_installments: number_of_installments,
        start_date: start_date,
        end_date: start_date + (number_of_installments * 14).days
      )

      # Save loan and create installments
      if loan.save
        create_installments_for_loan(loan, result[:installments])

        # Create device from credit application selected phone
        if credit_application && credit_application.selected_phone_model_id && credit_application.selected_imei
          create_device_for_loan(loan, credit_application)
        else
          Rails.logger.error "Cannot create device: missing selected phone data in credit application #{credit_application_id}. selected_phone_model_id: #{credit_application&.selected_phone_model_id}, selected_imei: #{credit_application&.selected_imei}"
          # Add error to loan but don't fail completely (device can be added later)
          loan.errors.add(:base, "Datos del dispositivo incompletos. Por favor, verifica la selección del teléfono.")
        end
      else
        Rails.logger.info "Loan save failed: errors=#{loan.errors.full_messages}, contract_number=#{loan.contract_number}"
        # Check if save failed due to contract number uniqueness
        if loan.errors[:contract_number].any?
          Rails.logger.info "Contract number uniqueness error, trying to find existing loan with contract_number: #{loan.contract_number}"
          # Try to find the existing loan with this contract number
          existing_loan = Loan.find_by(contract_number: loan.contract_number)
          if existing_loan
            Rails.logger.info "Found existing loan: id=#{existing_loan.id}, contract_number=#{existing_loan.contract_number}"
            return existing_loan
          else
            Rails.logger.error "No existing loan found with contract_number: #{loan.contract_number}"
          end
        end
      end

      loan
    end

    # Find existing draft loan for customer created today
    # We look for draft loans for this customer created recently
    def find_existing_draft_loan(customer, phone_price, approved_amount, credit_application_id)
      # First, try to find by credit_application_id if we store it somewhere
      # (currently not stored, but we could add it to session or loan metadata)

      # For now, find loans for this customer created in the last 7 days
      # This is a simplification - in production, we should have a better way
      # to associate loans with credit applications
      recent_date = 7.days.ago

      existing_loan = Loan.where(
        customer: customer,
        created_at: recent_date..Time.current
      ).order(created_at: :desc).first

      Rails.logger.info "find_existing_draft_loan: customer_id=#{customer.id}, found_loan_id=#{existing_loan&.id}, contract_number=#{existing_loan&.contract_number}"
      existing_loan
    end

    # Create installments for the loan
    def create_installments_for_loan(loan, installments_schedule)
      installments_schedule.each do |schedule|
        Installment.create!(
          loan: loan,
          installment_number: schedule[:installment_number],
          due_date: schedule[:due_date],
          amount: schedule[:amount],
          status: schedule[:status] || 'pending'
        )
      end
    end

    # Create device for loan from credit application selected phone
    def create_device_for_loan(loan, credit_application)
      Rails.logger.info "Creating device for loan #{loan.id} from credit application #{credit_application.id}"

      phone_model = credit_application.selected_phone_model
      imei = credit_application.selected_imei
      color = credit_application.selected_color || phone_model.color

      # Check if device with same IMEI already exists
      existing_device = Device.find_by(imei: imei)
      if existing_device
        Rails.logger.warn "Device with IMEI #{imei} already exists: id=#{existing_device.id}, loan_id=#{existing_device.loan_id}"
        if existing_device.loan_id.nil?
          # Device exists but not assigned to a loan, assign to this loan
          existing_device.update!(loan: loan)
          return existing_device
        else
          # Device already assigned to another loan - this is an error
          loan.errors.add(:base, "El IMEI #{imei} ya está asignado a otro dispositivo.")
          return nil
        end
      end

      # Create new device
      device = Device.new(
        loan: loan,
        phone_model: phone_model,
        imei: imei,
        brand: phone_model.brand,
        model: phone_model.model,
        color: color,
        lock_status: 'unlocked'
      )

      if device.save
        Rails.logger.info "Device created: id=#{device.id}, imei=#{device.imei}"
        device
      else
        Rails.logger.error "Failed to create device: #{device.errors.full_messages}"
        loan.errors.add(:base, "Error al crear dispositivo: #{device.errors.full_messages.join(', ')}")
        nil
      end
    end

    # Fetch customer date of birth from credit application
    def fetch_date_of_birth
      Rails.logger.info "fetch_date_of_birth called, params[:date_of_birth]: #{params[:date_of_birth].inspect}, session[:date_of_birth]: #{session[:date_of_birth].inspect}"
      # Try to get from params first
      if params[:date_of_birth].present?
        Rails.logger.info "Found date_of_birth in params: #{params[:date_of_birth]}"
        return params[:date_of_birth]
      end

      # Try to get from session
      if session[:date_of_birth].present?
        Rails.logger.info "Found date_of_birth in session: #{session[:date_of_birth]}"
        return session[:date_of_birth]
      end

      # Try to get from credit application
      if @credit_application_id.present?
        Rails.logger.info "Looking up credit application #{@credit_application_id}"
        credit_application = CreditApplication.find_by(id: @credit_application_id)
        if credit_application&.customer
          dob = credit_application.customer.date_of_birth
          Rails.logger.info "Found date_of_birth from credit application customer: #{dob}"
          return dob
        end
      end

      # Try to get from customer in session
      if session[:customer_id].present?
        Rails.logger.info "Looking up customer from session #{session[:customer_id]}"
        customer = Customer.find_by(id: session[:customer_id])
        if customer
          dob = customer.date_of_birth
          Rails.logger.info "Found date_of_birth from session customer: #{dob}"
          return dob
        end
      end

      Rails.logger.warn "No date_of_birth found in any source"
      nil
    end

    # Calculate customer age from date of birth
    def calculate_customer_age(date_of_birth)
      return nil unless date_of_birth.present?

      dob = date_of_birth.is_a?(Date) ? date_of_birth : Date.parse(date_of_birth.to_s) rescue nil
      return nil unless dob

      today = Date.today
      age = today.year - dob.year
      age -= 1 if today.yday < dob.yday
      age
    end
  end
end
