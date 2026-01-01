# frozen_string_literal: true

class SendLatePaymentWarningJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  # Warning milestones: specific days to send escalating warnings
  WARNING_THRESHOLDS = {
    3 => { level: "info", title: "Recordatorio de Pago", type: "payment_reminder" },
    7 => { level: "warning", title: "Aviso de Mora", type: "overdue_warning" },
    14 => { level: "urgent", title: "Aviso Importante", type: "overdue_warning" },
    27 => { level: "critical", title: "⚠️ Aviso Crítico", type: "device_lock" }
  }.freeze

  def perform
    log_execution("Starting: Sending late payment warning notifications")

    warning_count = send_warning_notifications
    log_execution("Completed: Sent #{warning_count} warning notifications", :info, { count: warning_count })
    track_metric("late_payment_warnings_sent", warning_count)
  rescue StandardError => e
    log_execution("Error sending late payment warnings: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def send_warning_notifications
    warning_count = 0

    # Find all customers with overdue installments
    Customer.joins(loans: :installments)
            .where(installments: { status: :overdue })
            .distinct
            .find_each do |customer|
      count = send_warnings_for_customer(customer)
      warning_count += count
    end

    warning_count
  end

  def send_warnings_for_customer(customer)
    return 0 unless customer.present?

    count = 0
    preference = customer.user&.notification_preference

    # Get earliest overdue installment
    earliest_overdue = customer.loans.joins(:installments)
                               .where(installments: { status: :overdue })
                               .minimum("installments.due_date")

    return 0 unless earliest_overdue.present?

    days_overdue = (Date.today - earliest_overdue).to_i

    # Check if this is a warning threshold day and customer should be notified
    WARNING_THRESHOLDS.each do |threshold_days, config|
      next unless days_overdue == threshold_days
      next if preference && !preference.can_receive_notification?(config[:type])
      next if preference && preference.in_quiet_hours?

      # Get overdue installments for context
      overdue_installments = customer.loans.joins(:installments)
                                      .where(installments: { status: :overdue })
                                      .order("installments.due_date")

      total_amount = overdue_installments.sum("installments.amount")

      # Create warning notification
      notification = build_warning_notification(customer, days_overdue, config, total_amount)
      notification.save! if notification

      count += 1 if notification
    end

    count
  end

  def build_warning_notification(customer, days_overdue, config, total_amount)
    title = config[:title]

    message = case days_overdue
              when 3
                "Tu pago está próximo a vencer. Monto: L. #{format('%.2f', total_amount)}. ¡Paga ahora!"
              when 7
                "Tu pago lleva 7 días en mora. Monto: L. #{format('%.2f', total_amount)}. Evita cargos adicionales."
              when 14
                "IMPORTANTE: Tu pago lleva 14 días en mora. Monto: L. #{format('%.2f', total_amount)}. Tu dispositivo corre peligro de bloqueo."
              when 27
                "⚠️ CRÍTICO: Tu dispositivo será BLOQUEADO en 3 DÍAS por mora de #{days_overdue} días. Monto: L. #{format('%.2f', total_amount)}. ¡PAGA AHORA!"
              else
                "Tu pago está en mora por #{days_overdue} días. Por favor, realiza el pago cuanto antes."
              end

    Notification.new(
      customer: customer,
      title: title,
      message: message,
      notification_type: config[:type],
      delivery_method: "fcm",
      status: "pending",
      data: {
        days_overdue: days_overdue,
        warning_level: config[:level],
        total_amount: total_amount,
        threshold: days_overdue
      }
    )
  end
end
