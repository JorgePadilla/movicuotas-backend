# frozen_string_literal: true

module Cobrador
  class DashboardController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize nil, policy_class: Cobrador::DashboardPolicy
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
          recent_locked: Device.locked.where("locked_at >= ?", 7.days.ago).count
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
      Cobrador::DashboardPolicy
    end
  end
end
