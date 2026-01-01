# frozen_string_literal: true

class MarkInstallmentsOverdueJob < ApplicationJob
  queue_as :reminders
  set_priority :high

  def perform
    log_execution("Starting: Marking past-due installments as overdue")

    updated_count = mark_overdue_installments
    log_execution("Completed: Marked #{updated_count} installments as overdue", :info, { count: updated_count })
    track_metric("installments_marked_overdue", updated_count)
  rescue StandardError => e
    log_execution("Error marking installments as overdue: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def mark_overdue_installments
    # Find all pending installments with past due dates
    overdue_installments = Installment.pending
                                      .where("due_date < ?", Date.today)

    updated_count = 0

    overdue_installments.find_each do |installment|
      if installment.mark_as_overdue
        updated_count += 1
      end
    end

    updated_count
  end
end
