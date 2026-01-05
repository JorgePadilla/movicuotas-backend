# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      Rails.logger.info "DashboardController#index - current_user: #{current_user&.email}, role: #{current_user&.role}, admin?: #{current_user&.admin?}"
      authorize nil, policy_class: Admin::DashboardPolicy

      # User statistics
      @total_users = User.count
      @admin_users = User.where(role: "admin").count
      @vendor_users = User.where(role: "supervisor").count
      @collector_users = User.where(role: "cobrador").count
      @active_users = User.where("updated_at >= ?", 30.days.ago).count

      # Customer statistics (system-wide)
      @total_customers = Customer.count
      @customers_with_active_loans = Customer.joins(:loans).where(loans: { status: "active" }).distinct.count
      @suspended_customers = Customer.where(status: "suspended").count
      @blocked_customers = Customer.where(status: "blocked").count

      # Loan statistics
      @total_loans = Loan.count
      @active_loans = Loan.where(status: "active").count
      @completed_loans = Loan.where(status: "completed").count
      @overdue_loans = Loan.joins(:installments).where(installments: { status: "overdue" }).distinct.count
      @total_loan_value = Loan.where(status: "active").sum(:total_amount)
      @average_loan_amount = @active_loans.positive? ? @total_loan_value / @active_loans : 0

      # Payment statistics
      @payments_this_month = Payment.where("payment_date >= ?", Date.today.beginning_of_month).sum(:amount)
      @total_revenue = Payment.sum(:amount)
      @overdue_amount = Installment.where(status: "overdue").sum(:amount)

      # Payment method distribution
      @cash_payments = Payment.where(payment_method: "cash").count
      @card_payments = Payment.where(payment_method: "card").count
      @transfer_payments = Payment.where(payment_method: "transfer").count

      # Device statistics
      @total_devices = Device.count
      @assigned_devices = Device.joins(:loan).count
      @available_devices = Device.left_joins(:loan).where(loans: { id: nil }).count

      # Branch statistics (based on branch_number in loans)
      @loans_by_branch = Loan.group(:branch_number).count
      @revenue_by_branch = Payment.joins(:loan).group("loans.branch_number").sum(:amount)

      # Recent activity
      @recent_loans = Loan.order(created_at: :desc).limit(10)
      @recent_payments = Payment.order(payment_date: :desc).limit(10)
      @recent_users = User.order(created_at: :desc).limit(5)
    end

    private

    def pundit_policy_class
      Admin::DashboardPolicy
    end
  end
end
