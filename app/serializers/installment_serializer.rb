class InstallmentSerializer
  def initialize(installment)
    @installment = installment
  end

  def as_json(*args)
    {
      id: @installment.id,
      loan_id: @installment.loan_id,
      installment_number: @installment.installment_number,
      due_date: @installment.due_date,
      amount: @installment.amount,
      status: @installment.status,
      paid_date: @installment.paid_date,
      days_overdue: calculate_days_overdue,
      is_overdue: @installment.overdue?,
      has_pending_payment: has_pending_payment?,
      payment_verification_status: latest_payment_status
    }
  end

  private

  def calculate_days_overdue
    return 0 unless @installment.overdue?
    (Date.today - @installment.due_date).to_i
  end

  def has_pending_payment?
    @installment.payments.where(verification_status: "pending").exists?
  end

  def latest_payment_status
    @installment.payments.order(created_at: :desc).first&.verification_status
  end
end
