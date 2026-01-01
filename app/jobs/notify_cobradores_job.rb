# frozen_string_literal: true

class NotifyCobradoresJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  def perform
    log_execution("Starting: Notifying cobradores with daily collection report")

    cobradores = User.where(role: "cobrador")
    notification_count = 0

    cobradores.find_each do |cobrador|
      next unless cobrador.present?

      # Get overdue stats
      overdue_count = Installment.where("due_date < ?", Date.today).count
      next if overdue_count.zero?

      # Create notification
      notification = Notification.create(
        recipient: cobrador,
        title: "📊 Reporte Diario de Mora",
        message: "Reporte de cobranza del día #{Date.today.strftime('%d/%m/%Y')}",
        notification_type: "daily_reminder",
        delivery_method: "fcm",
        status: "pending"
      )

      notification_count += 1 if notification.persisted?
    end

    log_execution("Completed: Notified #{notification_count} cobradores")
  rescue StandardError => e
    log_execution("Error: #{e.class} - #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end
end
