# frozen_string_literal: true

class CheckPaymentConfirmationsJob < ApplicationJob
  queue_as :notifications
  set_priority :default

  def perform
    log_execution("Starting: Checking payment confirmations")

    stats = check_and_notify_payments
    log_execution("Completed: Notified #{stats[:confirmed]} confirmed, #{stats[:rejected]} rejected payments", :info, stats)
    track_metric("payment_confirmations_notified", stats[:confirmed] + stats[:rejected])
  rescue StandardError => e
    log_execution("Error checking payment confirmations: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def check_and_notify_payments
    stats = { confirmed: 0, rejected: 0 }

    # Find recently verified payments that haven't been notified
    recently_verified = Payment.where(verification_status: "verified")
                               .where("verified_at > ?", 1.hour.ago)
                               .where(notified_at: nil)

    recently_verified.find_each do |payment|
      if notify_payment_confirmed(payment)
        stats[:confirmed] += 1
      end
    rescue StandardError => e
      log_execution("Error notifying confirmed payment #{payment.id}: #{e.message}", :error)
    end

    # Find recently rejected payments that haven't been notified
    recently_rejected = Payment.where(verification_status: "rejected")
                               .where("verified_at > ?", 1.hour.ago)
                               .where(notified_at: nil)

    recently_rejected.find_each do |payment|
      if notify_payment_rejected(payment)
        stats[:rejected] += 1
      end
    rescue StandardError => e
      log_execution("Error notifying rejected payment #{payment.id}: #{e.message}", :error)
    end

    stats
  end

  def notify_payment_confirmed(payment)
    customer = payment.loan&.customer
    return false unless customer

    Notification.send_payment_confirmation(customer, payment)

    # Mark as notified
    payment.update_column(:notified_at, Time.current)

    log_execution("Notified customer #{customer.id} of confirmed payment #{payment.id}", :debug)
    true
  end

  def notify_payment_rejected(payment)
    customer = payment.loan&.customer
    return false unless customer

    Notification.create!(
      customer: customer,
      title: "Pago rechazado",
      body: "Tu pago de L. #{format('%.2f', payment.amount)} fue rechazado. Motivo: #{payment.notes || 'No especificado'}. Por favor contacta a soporte.",
      notification_type: "payment_confirmation",
      metadata: { payment_id: payment.id, reason: payment.notes }
    )

    # Mark as notified
    payment.update_column(:notified_at, Time.current)

    log_execution("Notified customer #{customer.id} of rejected payment #{payment.id}", :debug)
    true
  end
end
