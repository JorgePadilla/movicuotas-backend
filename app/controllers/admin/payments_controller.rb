# frozen_string_literal: true

module Admin
  class PaymentsController < ApplicationController
    before_action :set_payment, only: [:show, :edit, :update, :destroy, :verify, :reject]

    # Available bank sources for payments
    BANK_SOURCES = [
      "BAC Honduras",
      "Banpais",
      "Banco Atlántida",
      "Banco Ficohsa",
      "Banco de Occidente",
      "Banco Promerica",
      "Tigo Money",
      "Efectivo en Tienda",
      "Otro"
    ].freeze

    def index
      @payments = policy_scope(Payment)

      # Filter by verification status if provided
      @payments = @payments.where(verification_status: params[:status]) if params[:status].present?

      # Filter by payment method if provided
      @payments = @payments.where(payment_method: params[:method]) if params[:method].present?

      # Filter by date range if provided
      if params[:date_from].present? && params[:date_to].present?
        date_from = Date.parse(params[:date_from])
        date_to = Date.parse(params[:date_to])
        @payments = @payments.where(payment_date: date_from..date_to)
      end

      # Search by customer name, contract number, or loan reference
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @payments = @payments.joins(loan: :customer)
                             .where("customers.full_name ILIKE ? OR loans.contract_number ILIKE ?", search_term, search_term)
                             .distinct
      end

      # Calculate summary statistics (from full unfiltered list for accurate totals)
      payments_for_stats = policy_scope(Payment)
      @total_payments = payments_for_stats.sum(:amount)
      @verified_payments = payments_for_stats.verified.sum(:amount)
      @pending_verification = payments_for_stats.pending_verification.sum(:amount)

      # Group by payment method for visualization
      @payments_by_method = payments_for_stats.group(:payment_method).sum(:amount)

      # Order by earliest installment due date (for verification queue), then by payment date
      @payments = @payments.left_joins(:installments)
                           .select("payments.*, MIN(installments.due_date) AS earliest_due_date")
                           .group("payments.id")
                           .order(Arel.sql("MIN(installments.due_date) ASC NULLS LAST, payments.payment_date DESC"))

      # Paginate results (20 per page)
      @payments = @payments.page(params[:page]).per(20)
    end

    def show
      authorize @payment
    end

    def new
      @payment = Payment.new
      authorize @payment
      @loans = loans_for_select
      @bank_sources = BANK_SOURCES
    end

    def create
      @payment = Payment.new(payment_params)
      authorize @payment

      # If created by Admin/Supervisor, auto-verify if requested
      if params[:auto_verify] == "1" && (current_user.admin? || current_user.supervisor?)
        @payment.verification_status = "verified"
        @payment.verified_by = current_user
        @payment.verified_at = Time.current
      end

      if @payment.save
        # Allocate to installments if specified
        allocate_to_installments if params[:installment_allocations].present?

        redirect_to admin_payment_path(@payment), notice: "Pago registrado correctamente."
      else
        @loans = loans_for_select
        @bank_sources = BANK_SOURCES
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @payment
      @loans = loans_for_select
      @bank_sources = BANK_SOURCES
    end

    def update
      authorize @payment

      if @payment.update(payment_params)
        # Handle verification image attachment
        if params[:payment][:verification_image].present?
          @payment.verification_image.attach(params[:payment][:verification_image])
        end

        # Reallocate to installments if specified
        allocate_to_installments if params[:installment_allocations].present?

        redirect_to admin_payment_path(@payment), notice: "Pago actualizado correctamente."
      else
        @loans = loans_for_select
        @bank_sources = BANK_SOURCES
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @payment

      if @payment.pending?
        @payment.destroy
        redirect_to admin_payments_path, notice: "Pago eliminado correctamente."
      else
        redirect_to admin_payment_path(@payment), alert: "No se puede eliminar un pago verificado o rechazado."
      end
    end

    def verify
      authorize @payment

      verification_options = {
        reference_number: params[:reference_number],
        bank_source: params[:bank_source],
        verification_image: params[:verification_image]
      }

      @payment.verify!(current_user, verification_options)
      redirect_to admin_payment_path(@payment), notice: "Pago verificado correctamente."
    rescue StandardError => e
      redirect_to admin_payment_path(@payment), alert: "Error al verificar pago: #{e.message}"
    end

    def reject
      authorize @payment
      reason = params[:rejection_reason].presence || "Sin razón especificada"
      @payment.reject!(current_user, reason)
      redirect_to admin_payment_path(@payment), alert: "Pago rechazado: #{reason}"
    rescue StandardError => e
      redirect_to admin_payment_path(@payment), alert: "Error al rechazar pago: #{e.message}"
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_payments_path, alert: "Pago no encontrado."
    end

    def payment_params
      params.require(:payment).permit(
        :loan_id,
        :amount,
        :payment_date,
        :payment_method,
        :reference_number,
        :bank_source,
        :notes,
        :receipt_image,
        :verification_image
      )
    end

    def loans_for_select
      # Admin and Supervisor can see all loans, Vendedor only their branch
      if current_user.admin? || current_user.supervisor?
        Loan.includes(:customer)
            .where(status: [:active, :overdue])
            .order("customers.full_name ASC")
            .map { |l| ["#{l.contract_number} - #{l.customer.full_name}", l.id] }
      else
        Loan.includes(:customer)
            .where(status: [:active, :overdue], branch_number: current_user.branch_number)
            .order("customers.full_name ASC")
            .map { |l| ["#{l.contract_number} - #{l.customer.full_name}", l.id] }
      end
    end

    def allocate_to_installments
      allocations = params[:installment_allocations].to_h.transform_values(&:to_d)
      @payment.allocate_to_installments(allocations) if allocations.values.sum.positive?
    end
  end
end
