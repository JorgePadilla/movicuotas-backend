# frozen_string_literal: true

module Supervisor
  class CollectionReportsController < ApplicationController
    def index
      authorize :collection_report, :index?
      skip_policy_scope

      @date_range = parse_date_range
      @report_data = fetch_collection_reports(@date_range)
      @recent_blocks = fetch_recent_blocks_paginated(@date_range)

      respond_to do |format|
        format.html
        format.csv { send_csv_export }
      end
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
      scope = Installment.overdue.where("(CURRENT_DATE - due_date) BETWEEN ? AND ?", min_days, max_days)
      {
        count: scope.count,
        total: scope.sum(:amount).to_f
      }
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

    def send_csv_export
      require "csv"

      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      filename = "collection_report_#{timestamp}.csv"

      send_data generate_csv,
                filename: filename,
                type: "text/csv"
    end

    def generate_csv
      CSV.generate(headers: true) do |csv|
        # Summary section
        csv << [ "Resumen de Cobranza" ]
        csv << [ "Total Cuotas Vencidas", @report_data[:summary][:total_overdue_count] ]
        csv << [ "Monto Total en Mora (RD$)", helpers.number_with_precision(@report_data[:summary][:total_overdue_amount], precision: 2) ]
        csv << [ "Dispositivos Bloqueados", @report_data[:summary][:devices_blocked] ]
        csv << [ "Dispositivos en Riesgo", @report_data[:summary][:devices_at_risk] ]
        csv << []

        # By days breakdown
        csv << [ "Desglose por Días de Mora" ]
        csv << %w[Rango Cantidad Monto]
        @report_data[:by_days].each do |range, data|
          csv << [ range, data[:count], helpers.number_with_precision(data[:total], precision: 2) ]
        end
        csv << []

        # By branch breakdown
        csv << [ "Desglose por Sucursal" ]
        csv << [ "Sucursal", "Préstamos", "Monto Total" ]
        @report_data[:by_branch].each do |branch_data|
          csv << [ branch_data[:branch], branch_data[:loan_count], helpers.number_with_precision(branch_data[:total_amount], precision: 2) ]
        end
        csv << []

        # Recent blocks
        csv << [ "Bloqueos Recientes" ]
        csv << [ "IMEI", "Cliente", "Contrato", "Dispositivo", "Fecha Bloqueo" ]
        @report_data[:recent_blocks].each do |block|
          csv << [
            block[:imei],
            block[:customer_name],
            block[:contract_number],
            block[:brand_model],
            block[:locked_at]&.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end
    end
  end
end
