class Customer < ApplicationRecord
  # Associations
  has_many :loans, dependent: :restrict_with_error
  has_many :credit_applications, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Validations
  validates :identification_number, presence: true, uniqueness: true,
            format: { with: /\A\d{13}\z/, message: "debe tener 13 dígitos" },
            length: { is: 13 }
  validates :full_name, presence: true
  validates :date_of_birth, presence: true
  validate :adult_customer
  validates :phone, presence: true,
            format: { with: /\A\d{8}\z/, message: "debe tener 8 dígitos" },
            length: { is: 8 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :status, inclusion: { in: %w[active suspended blocked] }

  # Enums
  enum :gender, { male: 'male', female: 'female', other: 'other' }, prefix: true
  enum :status, { active: 'active', suspended: 'suspended', blocked: 'blocked' }, default: 'active'

  # Scopes
  scope :with_active_loans, -> { joins(:loans).where(loans: { status: 'active' }) }
  scope :without_active_loans, -> { where.not(id: with_active_loans.select(:id)) }

  # Methods
  def age
    return nil unless date_of_birth
    today = Date.today
    age = today.year - date_of_birth.year
    age -= 1 if today.month < date_of_birth.month || (today.month == date_of_birth.month && today.day < date_of_birth.day)
    age
  end

  def adult?
    age.to_i >= 18
  end

  def adult_customer
    return unless date_of_birth.present?
    errors.add(:date_of_birth, "el cliente debe ser mayor de edad (18+)") unless adult?
  end

  def has_active_loan?
    loans.active.exists?
  end

  def latest_loan
    loans.order(created_at: :desc).first
  end
end
