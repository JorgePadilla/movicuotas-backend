# frozen_string_literal: true

class DailyCollectionReminderJob < ApplicationJob
  queue_as :reminders
  set_priority :high

  def perform
    log_execution("Starting: Sending daily collection reminders")

    sent_count = send_collection_reminders
    log_execution("Completed: Sent #{sent_count} collection reminders", :info, { count: sent_count })
    track_metric("collection_reminders_sent", sent_count)
  rescue StandardError => e
    log_execution("Error sending collection reminders: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def send_collection_reminders
    sent_count = 0

    # Find customers with overdue installments
    customers_with_overdue = Customer.joins(loans: :installments)
                                     .where(installments: { status: :overdue })
                                     .distinct

    customers_with_overdue.find_each do |customer|
      if send_reminder_to_customer(customer)
        sent_count += 1
      end
    rescue StandardError => e
      log_execution("Error sending reminder to customer #{customer.id}: #{e.message}", :error)
      # Continue with next customer
    end

    sent_count
  end

  def send_reminder_to_customer(customer)
    # Get the oldest overdue installment
    oldest_overdue = customer.loans.joins(:installments)
                             .where(installments: { status: :overdue })
                             .order("installments.due_date ASC")
                             .first&.installments&.overdue&.first

    return false unless oldest_overdue

    # Calculate days overdue
    days_overdue = (Date.today - oldest_overdue.due_date).to_i

    # Calculate total overdue amount
    total_overdue = customer.loans.joins(:installments)
                            .where(installments: { status: :overdue })
                            .sum("installments.amount")

    # Create notification
    Notification.create!(
      customer: customer,
      title: "Recordatorio de cobro",
      body: "Tienes #{days_overdue} días de atraso. Monto total pendiente: L. #{format('%.2f', total_overdue)}. Por favor realiza tu pago lo antes posible.",
      notification_type: "payment_reminder",
      metadata: {
        days_overdue: days_overdue,
        total_overdue: total_overdue,
        oldest_installment_id: oldest_overdue.id
      }
    )

    log_execution("Sent reminder to customer #{customer.id}: #{days_overdue} days overdue, L. #{total_overdue}", :debug)
    true
  end
end
