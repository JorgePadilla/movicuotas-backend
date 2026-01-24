class Payment < ApplicationRecord
  # Associations
  belongs_to :loan
  belongs_to :verified_by, class_name: "User", optional: true
  has_many :payment_installments, dependent: :destroy
  has_many :installments, through: :payment_installments

  # Attachments
  has_one_attached :receipt_image        # Image uploaded by customer via app
  has_one_attached :verification_image   # Image uploaded by supervisor during verification

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :payment_method, presence: true, inclusion: { in: %w[cash transfer card other] }
  validates :verification_status, presence: true, inclusion: { in: %w[pending verified rejected] }

  # Enums
  enum :payment_method, { cash: "cash", transfer: "transfer", card: "card", other: "other" }, default: "cash"
  enum :verification_status, { pending: "pending", verified: "verified", rejected: "rejected" }, default: "pending"

  # Scopes
  scope :verified, -> { where(verification_status: "verified") }
  scope :pending_verification, -> { where(verification_status: "pending") }
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

  # Verify payment with optional verification details
  # @param user [User] The user verifying the payment (Admin or Supervisor)
  # @param options [Hash] Optional verification details
  #   - :reference_number [String] Bank/Tigo Money reference number
  #   - :bank_source [String] Bank name or "Tigo Money"
  #   - :verification_image [ActionDispatch::Http::UploadedFile] Optional image
  def verify!(user, options = {})
    transaction do
      update!(
        verification_status: "verified",
        verified_by: user,
        verified_at: Time.current,
        reference_number: options[:reference_number],
        bank_source: options[:bank_source]
      )

      # Attach verification image if provided
      if options[:verification_image].present?
        verification_image.attach(options[:verification_image])
      end

      # Create audit log
      AuditLog.create!(
        user: user,
        action: "payment_verified",
        resource_type: self.class.name,
        resource_id: id,
        change_details: {
          payment_id: id,
          amount: amount,
          reference_number: reference_number,
          bank_source: bank_source
        }
      )
    end
  end

  # Reject payment with reason
  # @param user [User] The user rejecting the payment
  # @param reason [String] Reason for rejection
  def reject!(user, reason)
    transaction do
      update!(
        verification_status: "rejected",
        verified_by: user,
        verified_at: Time.current,
        notes: reason
      )

      # Create audit log
      AuditLog.create!(
        user: user,
        action: "payment_rejected",
        resource_type: self.class.name,
        resource_id: id,
        change_details: {
          payment_id: id,
          amount: amount,
          reason: reason
        }
      )
    end
  end

  private

  def update_installment_statuses
    # Update installments when payment is verified or rejected
    installments.each(&:update_paid_amount)
  end
end
