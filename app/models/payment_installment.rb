class PaymentInstallment < ApplicationRecord
  # Associations
  belongs_to :payment
  belongs_to :installment

  # Validations
  validates :payment, presence: true
  validates :installment, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :amount_within_installment_remaining
  validate :installment_matches_payment_loan

  # Callbacks
  after_save :update_installment_paid_amount
  after_destroy :update_installment_paid_amount

  private

  def amount_within_installment_remaining
    return unless amount.present? && installment.present?
    if amount > installment.remaining_amount
      errors.add(:amount, "no puede exceder el saldo pendiente de la cuota")
    end
  end

  def installment_matches_payment_loan
    return unless payment.present? && installment.present?
    if payment.loan_id != installment.loan_id
      errors.add(:installment, "debe pertenecer al mismo préstamo que el pago")
    end
  end

  def update_installment_paid_amount
    installment.update_paid_amount
  end
end
