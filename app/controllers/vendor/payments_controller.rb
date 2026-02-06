# frozen_string_literal: true

module Vendor
  class PaymentsController < ApplicationController
    include Sortable
    skip_after_action :verify_policy_scoped, only: :index

    # GET /vendor/payments
    # Payment tracking for vendor - lists only verified payments (confirmed)
    # Unverified payments (comprobantes) are only visible to admins for verification
    def index
      authorize :payment, :index?
      # Only show verified payments to vendors (business rule: unverified = comprobantes, verified = pagos)
      base_payments = policy_scope(Payment).verified.includes(:loan, loan: :customer)

      # Calculate stats from verified payments
      @total_count = base_payments.count
      @total_amount = base_payments.sum(:amount)
      @this_month_count = base_payments.where(payment_date: Date.current.beginning_of_month..Date.current.end_of_month).count
      @this_month_amount = base_payments.where(payment_date: Date.current.beginning_of_month..Date.current.end_of_month).sum(:amount)

      # Sort params
      set_sort_params(
        allowed_columns: %w[payment_date amount payment_method],
        default_column: "payment_date"
      )

      # Apply filters and sorting
      column_mapping = {
        "payment_date" => "payments.payment_date",
        "amount" => "payments.amount",
        "payment_method" => "payments.payment_method"
      }
      @payments = base_payments.order(sort_order_sql(column_mapping))

      # Filter by payment method
      @payments = @payments.where(payment_method: params[:method]) if params[:method].present?

      # Filter by date range
      if params[:date_from].present?
        @payments = @payments.where("payment_date >= ?", Date.parse(params[:date_from]))
      end
      if params[:date_to].present?
        @payments = @payments.where("payment_date <= ?", Date.parse(params[:date_to]))
      end

      # Search by customer name, contract number, or reference number
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @payments = @payments.joins(loan: :customer)
                             .where("customers.full_name ILIKE ? OR loans.contract_number ILIKE ? OR payments.reference_number ILIKE ?", search_term, search_term, search_term)
                             .distinct
      end

      # Paginate results (20 per page)
      @payments = @payments.page(params[:page]).per(20)
    end
  end
end
