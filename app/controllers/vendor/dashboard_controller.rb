# frozen_string_literal: true

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
      @total_loan_value = loans_scope.where(status: "active").sum(:total_amount)
      @average_loan_amount = @active_loans.positive? ? @total_loan_value / @active_loans : 0

      # Payment statistics (this month)
      @payments_this_month = Payment.joins(:loan)
                                    .where(loans: { id: loans_scope.select(:id) })
                                    .where("payment_date >= ?", Date.today.beginning_of_month)
                                    .sum(:amount)
      @overdue_installments = Installment.joins(:loan)
                                         .where(loans: { id: loans_scope.select(:id) })
                                         .where(status: "overdue")
                                         .count
      @overdue_amount = Installment.joins(:loan)
                                   .where(loans: { id: loans_scope.select(:id) })
                                   .where(status: "overdue")
                                   .sum(:amount)

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

    private

    def pundit_policy_class
      Vendor::DashboardPolicy
    end
  end
end
