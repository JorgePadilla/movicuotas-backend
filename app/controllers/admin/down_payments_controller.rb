# frozen_string_literal: true

module Admin
  class DownPaymentsController < ApplicationController
    before_action :set_loan, only: [ :show, :verify, :reject ]

    # GET /admin/down_payments
    # List all loans with pending down payment verification (deposits only)
    def index
      @loans = policy_scope(Loan)
                 .down_payment_pending_verification
                 .includes(:customer, :contract, :user)
                 .order(created_at: :desc)

      # Filter by branch if provided
      @loans = @loans.where(branch_number: params[:branch]) if params[:branch].present?

      # Search by customer name or contract number
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @loans = @loans.joins(:customer)
                       .where("customers.full_name ILIKE ? OR loans.contract_number ILIKE ?", search_term, search_term)
                       .distinct
      end

      # Statistics
      @pending_count = Loan.down_payment_pending_verification.count
      @total_pending_amount = Loan.down_payment_pending_verification.sum(:down_payment_amount)

      # Paginate
      @loans = @loans.page(params[:page]).per(20)
    end

    # GET /admin/down_payments/:id
    # Show details of a specific down payment for verification
    def show
      authorize @loan, :verify_down_payment?
      @customer = @loan.customer
      @contract = @loan.contract
    end

    # POST /admin/down_payments/:id/verify
    # Verify a deposit down payment
    def verify
      authorize @loan, :verify_down_payment?

      @loan.verify_down_payment!(current_user)
      redirect_to admin_down_payments_path,
                  notice: "Prima verificada exitosamente para #{@loan.customer.full_name}."
    end

    # POST /admin/down_payments/:id/reject
    # Reject a deposit down payment
    def reject
      authorize @loan, :verify_down_payment?

      reason = params[:reason].presence || "Comprobante inválido o ilegible"
      @loan.reject_down_payment!(current_user, reason)

      redirect_to admin_down_payments_path,
                  notice: "Prima rechazada para #{@loan.customer.full_name}. Razón: #{reason}"
    end

    private

    def set_loan
      @loan = Loan.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_down_payments_path, alert: "Préstamo no encontrado."
    end
  end
end
