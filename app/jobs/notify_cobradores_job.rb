# frozen_string_literal: true

class NotifyCobradorosJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  def perform
    log_execution("Starting: Notifying cobradores with daily collection report")

    notification_count = notify_all_cobradores
    log_execution("Completed: Notified #{notification_count} cobradores", :info, { count: notification_count })
    track_metric("cobradores_notified", notification_count)
  rescue StandardError => e
    log_execution("Error notifying cobradores: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def notify_all_cobradores
    notification_count = 0

    User.where(role: "cobrador").active.find_each do |cobrador|
      count = send_daily_report_to_cobrador(cobrador)
      notification_count += count
    end

    notification_count
  end

  def send_daily_report_to_cobrador(cobrador)
    return 0 unless cobrador.present?

    # Calculate overdue statistics
    stats = calculate_overdue_statistics

    return 0 if stats[:total_overdue_count].zero?

    # Create daily report notification
    title = "📊 Reporte Diario de Mora"
    message = build_report_message(stats)

    notification = Notification.create!(
      recipient: cobrador,
      title: title,
      message: message,
      notification_type: "daily_reminder",
      delivery_method: "fcm",
      status: "pending",
      data: stats
    )

    notification.persisted? ? 1 : 0
  rescue StandardError => e
    log_execution("Error creating daily report for cobrador #{cobrador.id}: #{e.message}", :error)
    0
  end

  def calculate_overdue_statistics
    overdue_installments = Installment.overdue.includes(loan: :customer)

    {
      total_overdue_count: overdue_installments.count,
      total_overdue_amount: overdue_installments.sum(:amount),
      by_days: {
        "1_to_7": count_by_range(1, 7),
        "8_to_15": count_by_range(8, 15),
        "16_to_30": count_by_range(16, 30),
        "30_plus": count_by_range(31, 999)
      },
      blocked_devices_count: Device.where(lock_status: :locked).count,
      blocked_today_count: Device.where(lock_status: :locked)
                                  .where("locked_at >= ?", Date.today.beginning_of_day)
                                  .count,
      pending_blocks_count: Device.where(lock_status: :pending).count
    }
  end

  def count_by_range(min_days, max_days)
    Installment.overdue
               .where("CAST(CURRENT_DATE AS date) - due_date BETWEEN ? AND ?", min_days, max_days)
               .count
  end

  def build_report_message(stats)
    message = <<~MSG
      📊 Reporte de Mora - #{Date.today.strftime('%d/%m/%Y')}

      💰 Total en Mora: L. #{format('%.2f', stats[:total_overdue_amount])}
      📦 Cuotas en mora: #{stats[:total_overdue_count]}

      Desglose por antigüedad:
      • 1-7 días: #{stats[:by_days][:"1_to_7"]} cuotas
      • 8-15 días: #{stats[:by_days][:"8_to_15"]} cuotas
      • 16-30 días: #{stats[:by_days][:"16_to_30"]} cuotas
      • 30+ días: #{stats[:by_days][:"30_plus"]} cuotas

      🔒 Dispositivos bloqueados: #{stats[:blocked_devices_count]}
      ⏳ Bloqueos pendientes: #{stats[:pending_blocks_count]}
      🆕 Bloqueados hoy: #{stats[:blocked_today_count]}

      ¡Inicia sesión en MOVICUOTAS para más detalles!
    MSG

    message.strip
  end
end
