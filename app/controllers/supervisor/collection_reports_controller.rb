# frozen_string_literal: true

module Supervisor
  class CollectionReportsController < ApplicationController
    def index
      @date_range = parse_date_range
      @report_data = fetch_collection_reports(@date_range)
      @recent_blocks = fetch_recent_blocks_paginated(@date_range)
    end

    private

    def parse_date_range
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        start_date..end_date
      else
        30.days.ago..Date.today
      end
    end

    def fetch_collection_reports(date_range)
      {
        summary: fetch_summary,
        by_days: fetch_overdue_by_days,
        by_branch: fetch_overdue_by_branch,
        recent_blocks: fetch_recent_blocks(date_range),
        recovery_rate: calculate_recovery_rate(date_range)
      }
    end

    def fetch_summary
      {
        total_overdue_count: Installment.overdue.count,
        total_overdue_amount: Installment.overdue.sum(:amount).to_f || 0.0,
        devices_blocked: Device.locked.count,
        devices_at_risk: Device.joins(loan: :installments)
                              .where(installments: { status: "overdue" })
                              .where(lock_status: "unlocked")
                              .distinct.count
      }
    end

    def fetch_overdue_by_days
      {
        "1-7 días": overdue_by_range(1, 7),
        "8-15 días": overdue_by_range(8, 15),
        "16-30 días": overdue_by_range(16, 30),
        "30+ días": overdue_by_range(31, 999)
      }
    end

    def overdue_by_range(min_days, max_days)
      Installment.overdue
                 .where("(CURRENT_DATE - due_date) BETWEEN ? AND ?", min_days, max_days)
                 .group_values_as_hash
                 .then do |results|
        {
          count: Installment.overdue
                           .where("(CURRENT_DATE - due_date) BETWEEN ? AND ?", min_days, max_days)
                           .count,
          total: Installment.overdue
                           .where("(CURRENT_DATE - due_date) BETWEEN ? AND ?", min_days, max_days)
                           .sum(:amount).to_f || 0.0
        }
      end
    end

    def fetch_overdue_by_branch
      Loan.joins(:installments)
          .where(installments: { status: "overdue" })
          .group(:branch_number)
          .select("branch_number, COUNT(DISTINCT loans.id) as loan_count, SUM(installments.amount) as total_amount")
          .map do |loan|
        {
          branch: loan.branch_number,
          loan_count: loan.loan_count,
          total_amount: loan.total_amount.to_f
        }
      end
    end

    def fetch_recent_blocks(date_range)
      Device.locked
            .where("locked_at >= ?", date_range.begin)
            .includes(loan: :customer)
            .order(locked_at: :desc)
            .limit(50)
            .map do |device|
        {
          imei: device.imei,
          customer_name: device.loan&.customer&.full_name,
          contract_number: device.loan&.contract_number,
          locked_at: device.locked_at,
          brand_model: "#{device.brand} #{device.model}"
        }
      end
    end

    def fetch_recent_blocks_paginated(date_range)
      Device.locked
            .where("locked_at >= ?", date_range.begin)
            .includes(loan: :customer)
            .order(locked_at: :desc)
            .page(params[:page])
            .per(20)
    end

    def calculate_recovery_rate(date_range)
      overdue_at_start = Installment.where("due_date < ?", date_range.begin)
                                   .where(status: "overdue")
                                   .sum(:amount).to_f || 0.0
      paid_during = Payment.where(payment_date: date_range).sum(:amount).to_f || 0.0

      return 0 if overdue_at_start.zero?
      ((paid_during / overdue_at_start) * 100).round(2)
    end
  end
end
