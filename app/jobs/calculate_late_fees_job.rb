# frozen_string_literal: true

class CalculateLateFeesJob < ApplicationJob
  queue_as :default
  set_priority :default

  # Late fee configuration
  # TBD: Confirm with business the exact percentages
  LATE_FEE_PERCENTAGE = 5  # 5% of overdue amount
  LATE_FEE_MAX_PERCENTAGE = 20  # Cap late fees at 20% of original amount
  CALCULATION_INTERVAL_DAYS = 7  # Only calculate fees once per week

  def perform
    log_execution("Starting: Calculating late fees for overdue installments")

    fee_count = calculate_and_apply_late_fees
    log_execution("Completed: Calculated late fees for #{fee_count} installments", :info, { count: fee_count })
    track_metric("late_fees_calculated", fee_count)
  rescue StandardError => e
    log_execution("Error calculating late fees: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def calculate_and_apply_late_fees
    fee_count = 0

    # Find overdue installments that haven't had fees calculated recently
    overdue_installments = find_eligible_overdue_installments

    overdue_installments.find_each do |installment|
      if apply_late_fee_to_installment(installment)
        fee_count += 1
      end
    rescue StandardError => e
      log_execution("Error applying late fee to installment #{installment.id}: #{e.message}", :error)
      # Continue with next installment
    end

    fee_count
  end

  def find_eligible_overdue_installments
    Installment.overdue
               .where("due_date < ?", Date.today - CALCULATION_INTERVAL_DAYS)
               .where("late_fee_calculated_at IS NULL OR late_fee_calculated_at < ?", 7.days.ago)
               .includes(:loan)
  end

  def apply_late_fee_to_installment(installment)
    return false if installment.nil? || installment.loan.nil?

    # Calculate days overdue
    days_overdue = (Date.today - installment.due_date).to_i
    return false if days_overdue <= 0

    # Calculate late fee amount
    late_fee = calculate_late_fee_amount(installment, days_overdue)
    return false if late_fee <= 0

    # Apply fee atomically with audit log
    ActiveRecord::Base.transaction do
      # Update installment with late fee
      installment.update!(
        late_fee_amount: late_fee,
        late_fee_calculated_at: Time.current
      )

      # Create audit log entry
      AuditLog.create!(
        user_id: get_system_user_id,
        action: "late_fee_calculated",
        resource_type: "Installment",
        resource_id: installment.id,
        change_details: {
          late_fee_amount: late_fee,
          days_overdue: days_overdue,
          original_amount: installment.amount,
          new_total: installment.amount + late_fee
        }
      )

      log_execution(
        "Applied late fee to installment #{installment.id}",
        :info,
        { late_fee: late_fee, days_overdue: days_overdue }
      )
    end

    true
  rescue StandardError => e
    log_execution("Transaction failed for installment #{installment.id}: #{e.message}", :error)
    false
  end

  def calculate_late_fee_amount(installment, days_overdue)
    # Base fee: percentage of overdue amount
    base_fee = (installment.amount * LATE_FEE_PERCENTAGE / 100.0).round(2)

    # Cap fees at maximum percentage of original amount
    max_fee = (installment.amount * LATE_FEE_MAX_PERCENTAGE / 100.0).round(2)

    # Apply the minimum of calculated fee or max fee
    # Don't re-calculate if already applied
    return 0 if installment.late_fee_amount.present? && installment.late_fee_amount > 0

    [base_fee, max_fee].min
  end

  def get_system_user_id
    # Get system user for audit trail
    system_user = User.find_by(email: "system@movicuotas.local")
    system_user&.id || User.first&.id || 1  # Fallback to first user or 1
  end
end
