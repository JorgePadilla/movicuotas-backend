# frozen_string_literal: true

module Vendor
  class PaymentsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    # GET /vendor/payments
    # Payment tracking for vendor - lists all payments for loans in vendor's branch
    def index
      authorize :payment, :index?
      @payments = policy_scope(Payment).includes(:loan, loan: :customer).order(payment_date: :desc)

      # Paginate results (20 per page)
      @payments = @payments.page(params[:page]).per(20)
    end

    # Note: Additional actions (show, create, etc.) can be added as needed
    # For now, we only need index for payment tracking
  end
end