class Loan < ApplicationRecord
  # Associations
  belongs_to :customer
  belongs_to :user  # Creator (admin or supervisor)
  belongs_to :down_payment_confirmed_by, class_name: "User", optional: true
  has_one :device, dependent: :destroy
  has_many :installments, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :contract, dependent: :destroy

  # ActiveStorage for down payment receipt
  has_one_attached :down_payment_receipt

  # Validations
  validates :contract_number, presence: true, uniqueness: true
  validates :branch_number, presence: true, format: { with: /\A[A-Z0-9]+\z/, message: "solo letras mayúsculas y números" }
  validates :status, presence: true, inclusion: { in: %w[draft active paid overdue cancelled] }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :approved_amount, presence: true, numericality: { greater_than: 0 }
  validates :down_payment_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, inclusion: { in: [ 30, 40, 50 ] }
  validates :down_payment_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :financed_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :number_of_installments, presence: true, numericality: { greater_than: 0 }, inclusion: { in: [ 6, 8, 12 ] }
  validates :start_date, presence: true
  validate :start_date_not_in_past
  validate :approved_amount_covers_total_amount

  # Enums
  enum :status, { draft: "draft", active: "active", paid: "paid", overdue: "overdue", cancelled: "cancelled" }, default: "draft"
  enum :down_payment_method, { cash: "cash", deposit: "deposit" }, prefix: :down_payment
  enum :down_payment_verification_status, {
    pending: "pending",
    verified: "verified",
    rejected: "rejected",
    not_required: "not_required"
  }, prefix: :down_payment

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :overdue, -> { where(status: "overdue") }
  scope :by_branch, ->(branch) { where(branch_number: branch) }
  scope :by_customer, ->(customer) { where(customer: customer) }
  scope :down_payment_pending_verification, -> { where(down_payment_verification_status: "pending") }

  # Callbacks
  before_validation :generate_contract_number, if: -> { contract_number.blank? }
  before_validation :calculate_amounts, if: -> { total_amount.present? && down_payment_percentage.present? }

  # Methods
  def total_paid
    payments.sum(:amount)
  end

  def remaining_balance
    financed_amount - total_paid
  end

  def next_installment
    installments.pending.order(:due_date).first
  end

  def overdue_installments
    installments.overdue
  end

  def paid_installments
    installments.paid
  end

  def pending_installments
    installments.pending
  end

  def mark_as_paid_if_completed
    return unless installments.pending.empty? && remaining_balance <= 0
    update(status: "paid")
  end

  def update_status_based_on_installments
    if overdue_installments.exists?
      update(status: "overdue")
    elsif pending_installments.exists?
      update(status: "active")
    else
      update(status: "paid")
    end
  end

  # Down Payment Collection Methods
  def down_payment_collected?
    down_payment_method.present? && down_payment_confirmed_at.present?
  end

  def down_payment_requires_verification?
    down_payment_deposit? && down_payment_pending?
  end

  def confirm_cash_down_payment!(user)
    update!(
      down_payment_method: "cash",
      down_payment_verification_status: "not_required",
      down_payment_confirmed_at: Time.current,
      down_payment_confirmed_by: user
    )
    AuditLog.create!(
      user: user,
      action: "down_payment_cash_confirmed",
      resource_type: "Loan",
      resource_id: id,
      change_details: { method: "cash", amount: down_payment_amount }
    )
  end

  def submit_deposit_down_payment!(user)
    update!(
      down_payment_method: "deposit",
      down_payment_verification_status: "pending",
      down_payment_confirmed_at: Time.current,
      down_payment_confirmed_by: user
    )
    AuditLog.create!(
      user: user,
      action: "down_payment_deposit_submitted",
      resource_type: "Loan",
      resource_id: id,
      change_details: { method: "deposit", amount: down_payment_amount }
    )
  end

  def verify_down_payment!(user)
    update!(
      down_payment_verification_status: "verified"
    )
    AuditLog.create!(
      user: user,
      action: "down_payment_verified",
      resource_type: "Loan",
      resource_id: id,
      change_details: { amount: down_payment_amount }
    )
  end

  def reject_down_payment!(user, reason)
    update!(
      down_payment_verification_status: "rejected",
      down_payment_rejection_reason: reason
    )
    AuditLog.create!(
      user: user,
      action: "down_payment_rejected",
      resource_type: "Loan",
      resource_id: id,
      change_details: { reason: reason, amount: down_payment_amount }
    )
  end

  def start_date_not_in_past
    return unless start_date.present?
    if start_date < Date.today
      errors.add(:start_date, "no puede ser en el pasado")
    end
  end

  def approved_amount_covers_total_amount
    return unless approved_amount.present? && total_amount.present?
    if approved_amount < total_amount
      errors.add(:approved_amount, "debe ser mayor o igual al monto total del teléfono")
    end
  end

  private

  def generate_contract_number
    # Format: {branch}-{date}-{sequence}
    date_part = Time.current.strftime("%Y-%m-%d")
    sequence = Loan.where(branch_number: branch_number, start_date: start_date).count + 1
    self.contract_number = "#{branch_number}-#{date_part}-#{sequence.to_s.rjust(6, '0')}"
  end

  def calculate_amounts
    self.down_payment_amount = total_amount * (down_payment_percentage / 100.0)
    self.financed_amount = total_amount - down_payment_amount
  end
end
