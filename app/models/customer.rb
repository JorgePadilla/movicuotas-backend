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
  enum :gender, { male: "male", female: "female", other: "other" }, prefix: true
  enum :status, { active: "active", suspended: "suspended", blocked: "blocked" }, default: "active"

  # Scopes
  scope :with_active_loans, -> { joins(:loans).where(loans: { status: "active" }) }
  scope :without_active_loans, -> { where.not(id: with_active_loans.select(:id)) }

  # Custom setter for date_of_birth to handle multiple date formats
  def date_of_birth=(value)
    return super(value) if value.is_a?(Date) || value.nil?

    # Try to parse as Date if it's already a Date object (e.g., from ActiveRecord)
    if value.respond_to?(:to_date)
      super(value.to_date)
      return
    end

    str = value.to_s.strip
    return super(nil) if str.empty?

    # Try ISO format (YYYY-MM-DD)
    if match = str.match(/\A(\d{4})-(\d{1,2})-(\d{1,2})\z/)
      year, month, day = match[1].to_i, match[2].to_i, match[3].to_i
      super(Date.new(year, month, day)) rescue super(Date.parse(str))
      return
    end

    # Try DD/MM/YYYY or DD-MM-YYYY
    if match = str.match(/\A(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\z/)
      day, month, year = match[1].to_i, match[2].to_i, match[3].to_i
      super(Date.new(year, month, day)) rescue super(Date.parse(str))
      return
    end

    # Fallback to Date.parse (handles other formats)
    super(Date.parse(str))
  rescue Date::Error
    # If parsing fails, set to nil and let validation fail
    super(nil)
  end

  # Methods
  def age
    return nil unless date_of_birth
    today = Date.today
    age = today.year - date_of_birth.year
    age -= 1 if today.month < date_of_birth.month || (today.month == date_of_birth.month && today.day < date_of_birth.day)
    age
  end

  def eligible_age?
    customer_age = age.to_i
    customer_age >= 21 && customer_age <= 60
  end

  def adult_customer
    return unless date_of_birth.present?

    customer_age = age.to_i
    if customer_age < 21
      errors.add(:date_of_birth, "el cliente debe tener al menos 21 años de edad (edad actual: #{customer_age} años)")
    elsif customer_age > 60
      errors.add(:date_of_birth, "el cliente debe tener máximo 60 años de edad (edad actual: #{customer_age} años)")
    end
  end

  def has_active_loan?
    loans.active.exists?
  end

  def latest_loan
    loans.order(created_at: :desc).first
  end
end
