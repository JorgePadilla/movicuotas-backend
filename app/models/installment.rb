class Installment < ApplicationRecord
  # Associations
  belongs_to :loan
  has_many :payment_installments, dependent: :destroy
  has_many :payments, through: :payment_installments

  # Validations
  validates :installment_number, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid overdue cancelled] }

  # Enums
  enum :status, { pending: "pending", paid: "paid", overdue: "overdue", cancelled: "cancelled" }, default: "pending"

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }
  scope :by_due_date, ->(date) { where(due_date: date) }
  scope :due_before, ->(date) { where("due_date < ?", date) }
  scope :due_after, ->(date) { where("due_date > ?", date) }

  # Callbacks
  before_save :update_status_based_on_due_date, if: -> { due_date_changed? || status_changed? }
  after_save :update_loan_status, if: -> { saved_change_to_status? }

  # Methods
  def days_overdue
    return 0 unless overdue? && due_date.present?
    (Date.today - due_date).to_i
  end

  def mark_as_paid(paid_amount, paid_date = Date.today)
    update(
      status: "paid",
      paid_date: paid_date,
      paid_amount: paid_amount
    )
  end

  def mark_as_overdue
    update(status: "overdue") if pending? && due_date.past?
  end

  def remaining_amount
    amount - paid_amount
  end

  def fully_paid?
    paid? && paid_amount >= amount
  end

  def update_paid_amount
    # Only count payments that have been verified
    verified_paid = payment_installments.joins(:payment)
                                        .where(payments: { verification_status: "verified" })
                                        .sum(:amount)
    update(paid_amount: verified_paid)

    # Update status based on verified paid amount
    if verified_paid >= amount
      update(status: "paid", paid_date: Date.today) unless paid?
    elsif paid? && verified_paid < amount
      # Revert to pending/overdue if payment was rejected
      new_status = due_date.past? ? "overdue" : "pending"
      update(status: new_status, paid_date: nil)
    end
  end

  private

  def update_status_based_on_due_date
    if pending? && due_date.past?
      self.status = "overdue"
    elsif overdue? && due_date.future?
      self.status = "pending"
    end
  end

  def update_loan_status
    loan.update_status_based_on_installments
  end
end
