class Payment < ApplicationRecord
  # Associations
  belongs_to :loan
  has_many :payment_installments, dependent: :destroy
  has_many :installments, through: :payment_installments
  has_one_attached :receipt_image

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :payment_method, presence: true, inclusion: { in: %w[cash transfer card other] }
  validates :verification_status, presence: true, inclusion: { in: %w[pending verified rejected] }

  # Enums
  enum :payment_method, { cash: 'cash', transfer: 'transfer', card: 'card', other: 'other' }, default: 'cash'
  enum :verification_status, { pending: 'pending', verified: 'verified', rejected: 'rejected' }, default: 'pending'

  # Scopes
  scope :verified, -> { where(verification_status: 'verified') }
  scope :pending_verification, -> { where(verification_status: 'pending') }
  scope :by_date, ->(date) { where(payment_date: date) }
  scope :by_loan, ->(loan) { where(loan: loan) }

  # Callbacks
  after_save :update_installment_statuses, if: -> { saved_change_to_amount? || saved_change_to_verification_status? }

  # Methods
  def allocate_to_installments(installment_ids_with_amounts)
    # installment_ids_with_amounts is a hash { installment_id => amount }
    transaction do
      installment_ids_with_amounts.each do |installment_id, amount|
        installment = Installment.find(installment_id)
        next unless installment.loan_id == loan_id

        payment_installments.create!(
          installment: installment,
          amount: amount
        )

        # Update installment paid amount (will mark as paid if fully allocated)
        installment.update_paid_amount
      end
    end
  end

  def total_allocated
    payment_installments.sum(:amount)
  end

  def unallocated_amount
    amount - total_allocated
  end

  def verify!(verified_by)
    update!(verification_status: 'verified')
    # Create audit log
    AuditLog.create!(
      user: verified_by,
      action: 'payment_verified',
      resource: self,
      changes: { verification_status: ['pending', 'verified'] }
    )
  end

  def reject!(rejected_by, reason)
    update!(verification_status: 'rejected', notes: reason)
    # Create audit log
    AuditLog.create!(
      user: rejected_by,
      action: 'payment_rejected',
      resource: self,
      changes: { verification_status: ['pending', 'rejected'] }
    )
  end

  private

  def update_installment_statuses
    return unless verified?
    installments.each(&:update_paid_amount)
  end
end
