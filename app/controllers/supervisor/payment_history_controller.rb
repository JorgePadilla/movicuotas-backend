# frozen_string_literal: true

module Supervisor
  class PaymentHistoryController < ApplicationController
    def show
      @loan = Loan.find(params[:loan_id])
      authorize @loan, :show?, policy_class: LoanPolicy
      @payment_history = fetch_payment_history(@loan)
    end

    private

    def fetch_payment_history(loan)
      {
        customer: {
          name: loan.customer.full_name,
          contract_number: loan.contract_number
        },
        summary: {
          total_installments: loan.number_of_installments,
          paid_installments: loan.installments.paid.count,
          pending_installments: loan.installments.pending.count,
          overdue_installments: loan.installments.overdue.count,
          total_paid: loan.payments.sum(:amount).to_f || 0.0,
          total_pending: loan.installments.pending.sum(:amount).to_f || 0.0
        },
        installments: loan.installments.order(:installment_number).map do |inst|
          {
            number: inst.installment_number,
            due_date: inst.due_date,
            amount: inst.amount,
            status: inst.status,
            paid_date: inst.paid_date,
            paid_amount: inst.paid_amount || 0.0,
            days_overdue: inst.overdue? ? (Date.today - inst.due_date).to_i : 0
          }
        end,
        payments: loan.payments.order(payment_date: :desc).map do |payment|
          {
            id: payment.id,
            date: payment.payment_date,
            amount: payment.amount,
            method: payment.payment_method,
            reference: payment.reference_number,
            verified: payment.verification_status == "verified",
            receipt_url: payment.receipt_image.attached? ? payment.receipt_image : nil
          }
        end
      }
    end
  end
end
