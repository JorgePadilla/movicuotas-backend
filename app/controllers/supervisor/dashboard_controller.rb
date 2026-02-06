# frozen_string_literal: true

module Supervisor
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize nil, policy_class: Supervisor::DashboardPolicy
      @dashboard_data = fetch_dashboard_metrics
    end

    private

    def fetch_dashboard_metrics
      {
        overdue_devices: {
          total_count: overdue_installments_count,
          total_amount: overdue_installments_amount,
          by_days: overdue_by_days_breakdown
        },
        blocked_devices: {
          locked_count: Device.locked.count,
          pending_count: Device.pending_lock.count,
          recent_locked: Device.locked.joins(:lock_states)
            .where("device_lock_states.status = 'locked' AND device_lock_states.confirmed_at >= ?", 7.days.ago)
            .distinct.count
        },
        pending_verifications: Payment.pending_verification.count,
        recent_blocks: DeviceLockState.locked_states
          .includes(device: { loan: :customer }, initiated_by: [])
          .order(created_at: :desc)
          .limit(5),
        today_payments: {
          count: Payment.verified.where(payment_date: Date.current).count,
          amount: Payment.verified.where(payment_date: Date.current).sum(:amount).to_f
        },
        this_month_payments: {
          count: Payment.verified.where(payment_date: Date.current.all_month).count,
          amount: Payment.verified.where(payment_date: Date.current.all_month).sum(:amount).to_f
        }
      }
    end

    def overdue_installments_count
      Installment.overdue.count
    end

    def overdue_installments_amount
      Installment.overdue.sum(:amount).to_f
    end

    def overdue_by_days_breakdown
      {
        "1-7": Installment.overdue.where("CURRENT_DATE - due_date <= 7").count,
        "8-15": Installment.overdue.where("CURRENT_DATE - due_date > 7 AND CURRENT_DATE - due_date <= 15").count,
        "16-30": Installment.overdue.where("CURRENT_DATE - due_date > 15 AND CURRENT_DATE - due_date <= 30").count,
        "30+": Installment.overdue.where("CURRENT_DATE - due_date > 30").count
      }
    end

    def pundit_policy_class
      Supervisor::DashboardPolicy
    end
  end
end
