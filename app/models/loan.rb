class Loan < ApplicationRecord
  # Associations
  belongs_to :customer
  belongs_to :user  # Creator (admin or vendedor)
  has_one :device, dependent: :destroy
  has_many :installments, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :contract, dependent: :destroy

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

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :overdue, -> { where(status: "overdue") }
  scope :by_branch, ->(branch) { where(branch_number: branch) }
  scope :by_customer, ->(customer) { where(customer: customer) }

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
