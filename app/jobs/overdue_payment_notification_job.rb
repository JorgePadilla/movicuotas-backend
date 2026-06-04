# frozen_string_literal: true

class OverduePaymentNotificationJob < ApplicationJob
  queue_as :reminders
  set_priority :high

  OVERDUE_SCHEDULE = {
    1 => {
      title: "Cuota Vencida",
      message: "Tu cuota está vencida. Ponte al día para evitar restricciones en tu dispositivo."
    },
    3 => {
      title: "Aviso Importante",
      message: "Tu dispositivo puede estar restringido. ¿Necesitas ayuda? Contáctanos."
    }
  }.freeze

  def perform
    log_execution("Starting: Overdue payment notifications")

    total_sent = 0
    OVERDUE_SCHEDULE.each do |days_after, config|
      count = send_overdue_notifications(days_after, config)
      total_sent += count
    end

    log_execution("Completed: Sent #{total_sent} overdue notifications", :info, { count: total_sent })
    track_metric("overdue_notifications_sent", total_sent)
  rescue StandardError => e
    log_execution("Error sending overdue notifications: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def send_overdue_notifications(days_after, config)
    target_date = Date.today - days_after
    count = 0

    # Find overdue installments that became overdue exactly days_after ago
    Installment.overdue
               .where(due_date: target_date)
               .includes(loan: :customer)
               .find_each do |installment|
      customer = installment.loan.customer
      next unless customer.present?

      # Don't create notifications that can only ever fail (no device to push to).
      next unless customer.device_tokens.active.exists?

      # Idempotency: skip if an overdue warning for this installment already exists today.
      next if overdue_already_sent?(customer, installment)

      begin
        Notification.create!(
          customer: customer,
          title: config[:title],
          message: config[:message],
          notification_type: "overdue_warning",
          delivery_method: "fcm",
          metadata: {
            installment_id: installment.id,
            loan_id: installment.loan_id,
            days_overdue: days_after
          }
        )
        count += 1
      rescue StandardError => e
        log_execution("Error creating overdue notification for installment #{installment.id}: #{e.message}", :error)
      end
    end

    log_execution("Sent #{count} notifications for #{days_after} days overdue", :debug)
    count
  end

  # metadata is a JSON-serialized TEXT column, so we match the installment id with
  # a LIKE against the serialized payload (e.g. ...,"installment_id":123,...).
  def overdue_already_sent?(customer, installment)
    customer.notifications
            .where(notification_type: "overdue_warning")
            .where("created_at >= ?", Time.current.beginning_of_day)
            .where("metadata LIKE ?", "%\"installment_id\":#{installment.id}%")
            .exists?
  end
end
