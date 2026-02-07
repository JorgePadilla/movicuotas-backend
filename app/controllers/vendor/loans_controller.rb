# frozen_string_literal: true

module Vendor
  class LoansController < ApplicationController
    include Sortable
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
    before_action :set_loan, only: [ :show, :download_contract, :block_device, :unblock_device, :verify_down_payment, :reject_down_payment ]

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
      authorize :loan, :index?
      base_loans = policy_scope(Loan).includes(:customer, :device)

      # Calculate stats from unfiltered data
      @active_count = base_loans.where(status: "active").count
      @completed_count = base_loans.where(status: %w[paid completed]).count
      @overdue_count = base_loans.where("overdue_installments_count > 0").count

      # Sort params
      set_sort_params(
        allowed_columns: %w[contract_number customer_name total_amount status created_at next_due_date],
        default_column: "created_at"
      )

      # Set default filters if no filters are provided (first visit to page)
      # Default: Active loans with overdue installments
      if params[:status].blank? && params[:cuotas].blank? && params[:device_status].blank? && params[:search].blank? && !params[:clear_filters] && !params[:filtered]
        @default_filters = true
        @status_filter = "active"
        @cuotas_filter = "con_vencidas"
        @device_status_filter = nil
      else
        @default_filters = false
        @status_filter = params[:status]
        @cuotas_filter = params[:cuotas]
        @device_status_filter = params[:device_status]
      end

      # Apply filters and sorting
      column_mapping = {
        "contract_number" => "loans.contract_number",
        "customer_name" => "customers.full_name",
        "total_amount" => "loans.total_amount",
        "status" => "loans.status",
        "created_at" => "loans.created_at",
        "next_due_date" => "loans.next_due_date"
      }
      @loans = base_loans.left_joins(:customer).order(sort_order_sql(column_mapping))

      # Filter by loan status
      if @status_filter.present?
        @loans = filter_loans_by_status(@loans, @status_filter)
      end

      # Filter by cuotas (installments) situation
      if @cuotas_filter.present?
        @loans = filter_loans_by_cuotas(@loans, @cuotas_filter)
      end

      # Filter by device lock status (MDM)
      if @device_status_filter.present?
        @loans = filter_loans_by_device_status(@loans, @device_status_filter)
      end

      # Search by customer name, contract number or IMEI
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @loans = @loans.left_joins(:customer, :device)
                       .where("customers.full_name ILIKE ? OR customers.identification_number ILIKE ? OR loans.contract_number ILIKE ? OR devices.imei ILIKE ?",
                              search_term, search_term, search_term, search_term)
                       .distinct
      end

      # Paginate results (20 per page)
      @loans = @loans.page(params[:page]).per(20)
    end

    # GET /vendor/loans/:id
    # Show loan details (optional, not part of core workflow)
    def show
      authorize @loan
      # Step 18: Loan Tracking Dashboard - Detailed view
      @installments = @loan.installments.order(:due_date)
      # Only show verified payments (pending payments are not visible to vendors)
      @payments = @loan.payments.where(verification_status: "verified").order(payment_date: :desc)

      # Payment summary data
      @total_verified_paid = @payments.sum(:amount)
      @total_allocated = @loan.total_allocated
      @total_excess = @total_verified_paid - @total_allocated
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

    # POST /vendor/loans/:id/block_device
    # Manually block the device
    def block_device
      authorize @loan, :block_device?

      device = @loan.device
      unless device
        redirect_to vendor_loan_path(@loan), alert: "Este préstamo no tiene un dispositivo asignado."
        return
      end

      if device.locked?
        redirect_to vendor_loan_path(@loan), alert: "El dispositivo ya está bloqueado."
        return
      end

      if device.lock!(current_user, "Bloqueo manual por vendedor")
        device.confirm_lock!
        redirect_to vendor_loan_path(@loan), notice: "Dispositivo bloqueado exitosamente."
      else
        redirect_to vendor_loan_path(@loan), alert: "No se pudo bloquear el dispositivo."
      end
    end

    # POST /vendor/loans/:id/unblock_device
    # Manually unblock the device
    def unblock_device
      authorize @loan, :unblock_device?

      device = @loan.device
      unless device
        redirect_to vendor_loan_path(@loan), alert: "Este préstamo no tiene un dispositivo asignado."
        return
      end

      unless device.locked?
        redirect_to vendor_loan_path(@loan), alert: "El dispositivo no está bloqueado."
        return
      end

      if device.unlock!(current_user, "Desbloqueo manual por vendedor")
        redirect_to vendor_loan_path(@loan), notice: "Dispositivo desbloqueado exitosamente."
      else
        redirect_to vendor_loan_path(@loan), alert: "No se pudo desbloquear el dispositivo."
      end
    end

    # POST /vendor/loans/:id/verify_down_payment
    def verify_down_payment
      authorize @loan, :verify_down_payment?

      @loan.verify_down_payment!(current_user)
      redirect_to vendor_loan_path(@loan), notice: "Prima aprobada exitosamente."
    end

    # POST /vendor/loans/:id/reject_down_payment
    def reject_down_payment
      authorize @loan, :verify_down_payment?

      reason = params[:reason].presence || "Comprobante inválido o ilegible"
      @loan.reject_down_payment!(current_user, reason)
      redirect_to vendor_loan_path(@loan), notice: "Prima rechazada. Razón: #{reason}"
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
        raise LoanFinalizationError, "La solicitud de crédito no pertenece al supervisor actual."
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
      when "active"
        loans.where(status: "active")
      when "completed"
        loans.where(status: %w[paid completed])
      when "overdue"
        loans.where(status: "overdue")
      when "draft"
        loans.where(status: "draft")
      else
        loans
      end
    end

    def filter_loans_by_cuotas(loans, cuotas_filter)
      case cuotas_filter
      when "con_vencidas"
        loans.where(
          "overdue_installments_count > 0 OR loans.id IN (?)",
          Installment.pending.where("due_date < ?", Date.current).select(:loan_id)
        )
      when "sin_vencidas"
        loans.where(overdue_installments_count: 0)
             .where.not(id: Installment.pending.where("due_date < ?", Date.current).select(:loan_id))
      when "proximas"
        loans.where(next_due_date: Date.current..7.days.from_now)
      when "pendientes"
        loans.where.not(next_due_date: nil)
      else
        loans
      end
    end

    def filter_loans_by_device_status(loans, device_status_filter)
      case device_status_filter
      when "locked"
        loans.joins(:device).merge(Device.locked)
      when "pending"
        loans.joins(:device).merge(Device.pending_lock)
      when "unlocked"
        loans.joins(:device).merge(Device.unlocked)
      else
        loans
      end
    end
  end
end
