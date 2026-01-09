# frozen_string_literal: true

class NotifySupervisorsJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  def perform
    log_execution("Starting: Notifying supervisors with daily collection report")

    supervisors = User.where(role: "supervisor")
    notification_count = 0

    supervisors.find_each do |supervisor|
      next unless supervisor.present?

      # Get overdue stats
      overdue_count = Installment.where("due_date < ?", Date.today).count
      next if overdue_count.zero?

      # Create notification
      notification = Notification.create(
        recipient: supervisor,
        title: "Reporte Diario de Mora",
        message: "Reporte de cobranza del dia #{Date.today.strftime('%d/%m/%Y')}",
        notification_type: "daily_reminder",
        delivery_method: "fcm",
        status: "pending"
      )

      notification_count += 1 if notification.persisted?
    end

    log_execution("Completed: Notified #{notification_count} supervisors")
  rescue StandardError => e
    log_execution("Error: #{e.class} - #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end
end
