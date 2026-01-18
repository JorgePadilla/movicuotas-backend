# frozen_string_literal: true

require "bigdecimal"

module Vendor
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize nil, policy_class: Vendor::DashboardPolicy

      # Customer statistics
      @total_customers = customers_scope.count
      @active_customers = customers_scope.where(status: "active").count
      @suspended_customers = customers_scope.where(status: "suspended").count
      @blocked_customers = customers_scope.where(status: "blocked").count

      # Device statistics (devices assigned to loans)
      @assigned_devices = devices_scope.count

      # Loan statistics
      @active_loans = loans_scope.where(status: "active").count
      total_loan_bd = BigDecimal(loans_scope.where(status: "active").sum(:total_amount).to_s)
      @total_loan_value = format_currency(total_loan_bd)
      @average_loan_amount = @active_loans.positive? ? format_currency(total_loan_bd / BigDecimal(@active_loans)) : "0.00"

      # Payment statistics (this month)
      payments_bd = BigDecimal(Payment.joins(:loan)
                                    .where(loans: { id: loans_scope.select(:id) })
                                    .where("payment_date >= ?", Date.today.beginning_of_month)
                                    .sum(:amount).to_s)
      @payments_this_month = format_currency(payments_bd)

      @overdue_installments = Installment.joins(:loan)
                                         .where(loans: { id: loans_scope.select(:id) })
                                         .where(status: "overdue")
                                         .count
      overdue_bd = BigDecimal(Installment.joins(:loan)
                                   .where(loans: { id: loans_scope.select(:id) })
                                   .where(status: "overdue")
                                   .sum(:amount).to_s)
      @overdue_amount = format_currency(overdue_bd)

      # Recent payments (last 10)
      @recent_payments = Payment.joins(loan: :customer)
                                .where(loans: { id: loans_scope.select(:id) })
                                .order(payment_date: :desc)
                                .limit(10)

      # Upcoming due dates (next 7 days)
      @upcoming_installments = Installment.joins(loan: :customer)
                                          .where(loans: { id: loans_scope.select(:id) })
                                          .where(status: "pending")
                                          .where("due_date <= ?", 7.days.from_now)
                                          .order(:due_date)
                                          .limit(10)
    end

    private

    def format_currency(value)
      # Format BigDecimal to exactly 2 decimal places with thousand separators
      bd = value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
      rounded = bd.round(2)
      view_context.number_with_delimiter(rounded, delimiter: ",", separator: ".")
    end

    def loans_scope
      if current_user.admin?
        Loan.all
      else
        current_user.loans
      end
    end

    def customers_scope
      Customer.joins(:loans).where(loans: { id: loans_scope.select(:id) }).distinct
    end

    def devices_scope
      Device.joins(:loan).where(loans: { id: loans_scope.select(:id) })
    end

    def pundit_policy_class
      Vendor::DashboardPolicy
    end
  end
end
