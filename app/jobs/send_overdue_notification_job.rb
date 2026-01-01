# frozen_string_literal: true

class SendOverdueNotificationJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  # Milestone days for escalating notifications
  NOTIFICATION_THRESHOLDS = [ 1, 7, 14, 30 ].freeze

  def perform
    log_execution("Starting: Sending overdue payment notifications")

    notification_count = send_notifications_for_overdue
    log_execution("Completed: Sent #{notification_count} overdue notifications", :info, { count: notification_count })
    track_metric("overdue_notifications_sent", notification_count)
  rescue StandardError => e
    log_execution("Error sending overdue notifications: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def send_notifications_for_overdue
    notification_count = 0

    # Find all customers with overdue installments
    Customer.joins(loans: :installments)
            .where(installments: { status: :overdue })
            .distinct
            .find_each do |customer|
      # Get the earliest overdue installment to calculate days
      earliest_overdue = customer.loans.joins(:installments)
                                  .where(installments: { status: :overdue })
                                  .minimum("installments.due_date")

      next unless earliest_overdue.present?

      days_overdue = (Date.today - earliest_overdue).to_i

      # Check if this customer should receive a notification at this threshold
      if should_send_notification?(customer, days_overdue)
        notification_count += send_notification_to_customer(customer, days_overdue)
      end
    end

    notification_count
  end

  def should_send_notification?(customer, days_overdue)
    # Only send if days match a threshold
    return false unless NOTIFICATION_THRESHOLDS.include?(days_overdue) || days_overdue > 30

    # Check customer's notification preferences
    preference = customer.user&.notification_preference
    return true if preference.nil?  # Default to sending if no preference

    preference.can_receive_notification?("overdue_warning") &&
      !preference.in_quiet_hours?
  end

  def send_notification_to_customer(customer, days_overdue)
    return 0 unless customer.present?

    count = 0

    # Get all overdue installments for this customer
    overdue_installments = customer.loans.joins(:installments)
                                    .where(installments: { status: :overdue })
                                    .pluck("installments.*")
                                    .map { |attrs| Installment.instantiate(attrs) }

    total_overdue = overdue_installments.sum(&:amount)

    # Create notification
    notification_data = {
      days_overdue: days_overdue,
      installment_count: overdue_installments.count,
      total_amount: total_overdue
    }

    notification = Notification.send_overdue_warning(
      customer,
      overdue_installments.first,
      days_overdue
    )

    notification.update(data: notification_data) if notification.persisted?

    count = notification.persisted? ? 1 : 0

    # For 30+ days, also send escalation message
    if days_overdue >= 30
      send_escalation_notification(customer, days_overdue, total_overdue)
      count += 1
    end

    count
  end

  def send_escalation_notification(customer, days_overdue, total_amount)
    Notification.create!(
      customer: customer,
      title: "⚠️ Aviso urgente de bloqueo de dispositivo",
      message: "Tu dispositivo será bloqueado hoy por mora de #{days_overdue} días. Monto en mora: L. #{format('%.2f', total_amount)}.",
      notification_type: "device_blocking_alert",
      delivery_method: "fcm",
      status: "pending",
      data: {
        days_overdue: days_overdue,
        total_amount: total_amount,
        escalation: true
      }
    )
  rescue StandardError => e
    log_execution("Error creating escalation notification for customer #{customer.id}: #{e.message}", :error)
  end
end
