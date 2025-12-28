# frozen_string_literal: true

module Vendor
  class LoansController < ApplicationController
    # Step 15: Crédito Aplicado (Loan Finalization & Success)
    # This controller handles loan finalization after all previous steps are completed.
    #
    # Flow:
    # 1. User arrives here after signing contract (Step 14)
    # 2. System finalizes loan creation with all dependencies
    # 3. Displays success screen (Step 15) with two action buttons
    #
    # Required parameters (should come from previous steps):
    # - credit_application_id: Approved credit application
    # - device_id: Selected device with IMEI
    # - contract_id: Signed contract
    # - loan_attributes: Payment calculator results (total_amount, down_payment_percentage, etc.)

    before_action :set_prerequisites, only: [ :create ]
    before_action :set_loan, only: [ :show, :download_contract ]

    # GET /vendor/loans/new
    # This would be the entry point from Step 14 (contract signature)
    def new
      # In a real flow, we would retrieve the data from session or previous steps
      # For now, redirect to customer search if no prerequisites in session
      unless session[:credit_application_id] && session[:device_id] && session[:contract_id]
        redirect_to vendor_customer_search_path,
                    alert: "Por favor complete los pasos anteriores primero."
        return
      end

      @credit_application = CreditApplication.find(session[:credit_application_id])
      @device = Device.find(session[:device_id])
      @contract = Contract.find(session[:contract_id])
      @loan_attributes = session[:loan_attributes] || {}

      authorize :loan, :create?
    end

    # POST /vendor/loans
    # Finalize the loan creation and display success screen (Step 15)
    def create
      authorize :loan, :create?

      begin
        service = LoanFinalizationService.new(
          credit_application: @credit_application,
          device: @device,
          loan_attributes: loan_params.to_h,
          contract: @contract,
          current_user: current_user
        )

        @loan = service.finalize!

        # Clear session data as loan is now finalized
        clear_session_data

        # Render success screen (Step 15)
        render :create, status: :created

      rescue LoanFinalizationError => e
        flash.now[:alert] = e.message
        render :new, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound => e
        flash.now[:alert] = "No se encontraron los datos requeridos. Por favor complete los pasos anteriores."
        render :new, status: :unprocessable_entity
      end
    end

    # GET /vendor/loans
    # Step 18: Loan Tracking Dashboard - List all loans for tracking
    def index
      @loans = policy_scope(Loan).order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present? && params[:status] != "Todos los estados"
        @loans = filter_loans_by_status(@loans, params[:status])
      end

      authorize :loan, :index?
    end

    # GET /vendor/loans/:id
    # Show loan details (optional, not part of core workflow)
    def show
      authorize @loan
      # Step 18: Loan Tracking Dashboard - Detailed view
      @installments = @loan.installments.order(:due_date)
      @payments = @loan.payments.order(payment_date: :desc)
    end

    # GET /vendor/loans/:id/download_contract
    # Download the signed contract as PDF
    def download_contract
      authorize @loan

      # Generate PDF using ContractGeneratorService (placeholder)
      pdf_content = @loan.contract&.generate_pdf || "Contrato no disponible"

      send_data pdf_content,
                filename: "contrato-#{@loan.contract_number}.pdf",
                type: "application/pdf",
                disposition: "attachment"
    end

    private

    def set_prerequisites
      # In a real implementation, these would come from session or workflow state
      # For now, we'll use parameters for testing
      @credit_application = CreditApplication.find(params[:credit_application_id])
      @device = Device.find(params[:device_id])
      @contract = Contract.find(params[:contract_id])

      # Verify all prerequisites are owned by current vendor and in correct state
      verify_prerequisites_ownership!
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "No se encontraron los datos requeridos. Por favor complete los pasos anteriores."
      redirect_to vendor_customer_search_path
    end

    def set_loan
      @loan = Loan.find(params[:id])
    end

    def loan_params
      params.require(:loan).permit(
        :total_amount,
        :down_payment_percentage,
        :number_of_installments,
        :interest_rate
      )
    end

    def verify_prerequisites_ownership!
      # Verify credit application belongs to current vendor
      unless @credit_application.vendor == current_user
        raise LoanFinalizationError, "La solicitud de crédito no pertenece al vendedor actual."
      end

      # Verify contract is not already linked to a loan
      if @contract.loan.present?
        raise LoanFinalizationError, "El contrato ya está vinculado a otro crédito."
      end

      # Verify device is not already assigned
      if @device.loan.present?
        raise LoanFinalizationError, "El dispositivo ya está asignado a otro crédito."
      end

      # Verify credit application is approved
      unless @credit_application.approved?
        raise LoanFinalizationError, "La solicitud de crédito no está aprobada."
      end

      # Verify contract is signed
      unless @contract.signed?
        raise LoanFinalizationError, "El contrato no está firmado."
      end
    end

    def clear_session_data
      session.delete(:credit_application_id)
      session.delete(:device_id)
      session.delete(:contract_id)
      session.delete(:loan_attributes)
    end

    def filter_loans_by_status(loans, status_filter)
      case status_filter
      when "Activos"
        loans.where(status: "active")
      when "Completados"
        loans.where(status: "paid")
      when "En mora"
        # Loans with overdue installments
        loans.joins(:installments).where(installments: { status: "overdue" }).distinct
      else
        loans
      end
    end
  end
end
