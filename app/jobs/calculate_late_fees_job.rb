# frozen_string_literal: true

class CalculateLateFeesJob < ApplicationJob
  queue_as :default
  set_priority :default

  # ⚠️ BUSINESS DECISION PENDING
  # Late fee rules have NOT been defined by business yet.
  # This job is scheduled and infrastructure is ready, but NO FEES are applied.
  #
  # To implement late fees, define business rules for:
  # 1. When should late fees start? (e.g., 7 days overdue)
  # 2. How should they be calculated? (fixed amount, percentage, tiered)
  # 3. What are the caps/limits? (minimum, maximum per installment)
  # 4. Should fees compound or reset? (weekly, monthly, once)
  # 5. Should customers be notified of fees? (yes/no, when)
  #
  # Once rules are defined, uncomment the implementation below and test thoroughly.

  def perform
    log_execution("Starting: Late fees job (not yet configured by business)")

    # TODO: Implement late fee calculation once business rules are defined
    # fee_count = calculate_and_apply_late_fees
    # log_execution("Completed: Calculated late fees for #{fee_count} installments", :info, { count: fee_count })

    log_execution("Late fees: Waiting for business to define rules", :info)
    track_metric("late_fees_job_run", 1)
  rescue StandardError => e
    log_execution("Error in late fees job: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  # TODO: Uncomment and implement when business defines late fee rules
  #
  # def calculate_and_apply_late_fees
  #   fee_count = 0
  #
  #   # Find overdue installments that haven't had fees calculated recently
  #   overdue_installments = find_eligible_overdue_installments
  #
  #   overdue_installments.find_each do |installment|
  #     if apply_late_fee_to_installment(installment)
  #       fee_count += 1
  #     end
  #   rescue StandardError => e
  #     log_execution("Error applying late fee to installment #{installment.id}: #{e.message}", :error)
  #     # Continue with next installment
  #   end
  #
  #   fee_count
  # end
  #
  # def find_eligible_overdue_installments
  #   Installment.overdue
  #              .where("due_date < ?", Date.today - 7)  # At least 7 days overdue
  #              .where("late_fee_calculated_at IS NULL OR late_fee_calculated_at < ?", 7.days.ago)
  #              .includes(:loan)
  # end
  #
  # def apply_late_fee_to_installment(installment)
  #   return false if installment.nil? || installment.loan.nil?
  #
  #   # Calculate days overdue
  #   days_overdue = (Date.today - installment.due_date).to_i
  #   return false if days_overdue <= 0
  #
  #   # Calculate late fee amount based on business rules
  #   late_fee = calculate_late_fee_amount(installment, days_overdue)
  #   return false if late_fee <= 0
  #
  #   # Apply fee atomically with audit log
  #   ActiveRecord::Base.transaction do
  #     # Update installment with late fee
  #     installment.update!(
  #       late_fee_amount: late_fee,
  #       late_fee_calculated_at: Time.current
  #     )
  #
  #     # Create audit log entry
  #     AuditLog.create!(
  #       user_id: get_system_user_id,
  #       action: "late_fee_calculated",
  #       resource_type: "Installment",
  #       resource_id: installment.id,
  #       change_details: {
  #         late_fee_amount: late_fee,
  #         days_overdue: days_overdue,
  #         original_amount: installment.amount,
  #         new_total: installment.amount + late_fee
  #       }
  #     )
  #
  #     log_execution(
  #       "Applied late fee to installment #{installment.id}",
  #       :info,
  #       { late_fee: late_fee, days_overdue: days_overdue }
  #     )
  #   end
  #
  #   true
  # rescue StandardError => e
  #   log_execution("Transaction failed for installment #{installment.id}: #{e.message}", :error)
  #   false
  # end
  #
  # def calculate_late_fee_amount(installment, days_overdue)
  #   # EXAMPLE: 5% of overdue amount, capped at 20%
  #   # IMPLEMENT: Replace with actual business rules
  #   #
  #   # base_fee = (installment.amount * 5.0 / 100).round(2)
  #   # max_fee = (installment.amount * 20.0 / 100).round(2)
  #   # return 0 if installment.late_fee_amount.present? && installment.late_fee_amount > 0
  #   # [base_fee, max_fee].min
  # end
  #
  # def get_system_user_id
  #   system_user = User.find_by(email: "system@movicuotas.local")
  #   system_user&.id || User.first&.id || 1
  # end
end
