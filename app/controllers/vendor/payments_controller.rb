# frozen_string_literal: true

module Vendor
  class PaymentsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    # GET /vendor/payments
    # Payment tracking for vendor - lists all payments for loans in vendor's branch
    def index
      authorize :payment, :index?
      base_payments = policy_scope(Payment).includes(:loan, loan: :customer)

      # Calculate stats from unfiltered data
      @verified_count = base_payments.verified.count
      @pending_count = base_payments.pending_verification.count
      @total_amount = base_payments.sum(:amount)

      # Apply filters
      @payments = base_payments.order(payment_date: :desc)

      # Filter by verification status
      @payments = @payments.where(verification_status: params[:status]) if params[:status].present?

      # Search by customer name or contract number
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @payments = @payments.joins(loan: :customer)
                             .where("customers.full_name ILIKE ? OR loans.contract_number ILIKE ?", search_term, search_term)
                             .distinct
      end

      # Paginate results (20 per page)
      @payments = @payments.page(params[:page]).per(20)
    end
  end
end