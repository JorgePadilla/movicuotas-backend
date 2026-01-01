# frozen_string_literal: true

module Admin
  class PaymentsController < ApplicationController
    before_action :set_payment, only: [:show]

    def index
      @payments = policy_scope(Payment).order(payment_date: :desc)

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

      # Calculate summary statistics
      @total_payments = @payments.sum(:amount)
      @verified_payments = @payments.verified.sum(:amount)
      @pending_verification = @payments.pending_verification.sum(:amount)

      # Group by payment method for visualization
      @payments_by_method = @payments.group(:payment_method).sum(:amount)
    end

    def show
      authorize @payment
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_payments_path, alert: "Pago no encontrado."
    end
  end
end
