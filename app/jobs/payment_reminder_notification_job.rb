# frozen_string_literal: true

class PaymentReminderNotificationJob < ApplicationJob
  queue_as :reminders
  set_priority :high

  REMINDER_SCHEDULE = {
    3 => {
      title: "Recordatorio de Pago",
      message: "Tu próxima cuota vence en 3 días. Monto: L. %{amount}, Fecha: %{date}"
    },
    1 => {
      title: "Pago Mañana",
      message: "Mañana vence tu cuota. Evita atrasos pagando L. %{amount} a tiempo"
    },
    0 => {
      title: "Pago Hoy",
      message: "Hoy vence tu cuota. Paga hoy L. %{amount} y mantén tu teléfono activo."
    }
  }.freeze

  def perform
    log_execution("Starting: Payment reminder notifications")

    total_sent = 0
    REMINDER_SCHEDULE.each do |days_before, config|
      count = send_reminders_for_day(days_before, config)
      total_sent += count
    end

    log_execution("Completed: Sent #{total_sent} payment reminders", :info, { count: total_sent })
    track_metric("payment_reminders_sent", total_sent)
  rescue StandardError => e
    log_execution("Error sending payment reminders: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def send_reminders_for_day(days_before, config)
    target_date = Date.today + days_before
    count = 0

    # Find pending installments due on target_date
    Installment.pending
               .where(due_date: target_date)
               .includes(loan: :customer)
               .find_each do |installment|
      customer = installment.loan.customer
      next unless customer.present?

      begin
        Notification.create!(
          customer: customer,
          title: config[:title],
          message: format(config[:message],
                         amount: installment.amount.ceil,
                         date: installment.due_date.strftime("%d/%m/%Y")),
          notification_type: "payment_reminder",
          delivery_method: "fcm",
          metadata: {
            installment_id: installment.id,
            loan_id: installment.loan_id,
            days_before: days_before
          }
        )
        count += 1
      rescue StandardError => e
        log_execution("Error creating reminder for installment #{installment.id}: #{e.message}", :error)
      end
    end

    log_execution("Sent #{count} reminders for #{days_before} days before due date", :debug)
    count
  end
end
