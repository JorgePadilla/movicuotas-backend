class CreditApplication < ApplicationRecord
  # Associations
  belongs_to :customer
  belongs_to :vendor, class_name: "User", optional: true
  has_one_attached :id_front_image
  has_one_attached :id_back_image
  has_one_attached :facial_verification_image

  accepts_nested_attributes_for :customer

  # Enums
  enum :employment_status, { employed: "employed", self_employed: "self_employed", unemployed: "unemployed", student: "student", retired: "retired" }, prefix: true
  enum :salary_range, { less_than_10000: "less_than_10000", range_10000_20000: "10000_20000", range_20000_30000: "20000_30000", range_30000_40000: "30000_40000", more_than_40000: "more_than_40000" }, prefix: true
  enum :verification_method, { sms: "sms", whatsapp: "whatsapp", email: "email" }, prefix: true
  # Validations
  validates :application_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validate :approved_amount_present_if_approved
  validates :employment_status, inclusion: { in: CreditApplication.employment_statuses.keys }, allow_blank: true
  validates :salary_range, inclusion: { in: CreditApplication.salary_ranges.keys }, allow_blank: true
  validates :verification_method, inclusion: { in: CreditApplication.verification_methods.keys }, allow_blank: true

  # Enums
  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, default: "pending"

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :by_vendor, ->(vendor) { where(vendor: vendor) }
  scope :by_customer, ->(customer) { where(customer: customer) }

  # Callbacks
  before_validation :generate_application_number, if: -> { application_number.blank? }

  # Methods
  def approve!(approved_amount, approved_by = nil)
    update!(
      status: "approved",
      approved_amount: approved_amount
    )

    # Create audit log
    AuditLog.create!(
      user: approved_by,
      action: "credit_application_approved",
      resource: self,
      changes: { status: [ "pending", "approved" ], approved_amount: [ nil, approved_amount ] }
    ) if approved_by
  end

  def reject!(reason, rejected_by = nil)
    update!(
      status: "rejected",
      rejection_reason: reason
    )

    # Create audit log
    AuditLog.create!(
      user: rejected_by,
      action: "credit_application_rejected",
      resource: self,
      changes: { status: [ "pending", "rejected" ], rejection_reason: [ nil, reason ] }
    ) if rejected_by
  end

  def can_be_processed?
    pending? && id_front_image.attached? && id_back_image.attached? && facial_verification_image.attached?
  end

  def approved_amount_present_if_approved
    if approved? && approved_amount.blank?
      errors.add(:approved_amount, "debe estar presente cuando la solicitud está aprobada")
    end
  end

  private

  def generate_application_number
    date_part = Time.current.strftime("%Y%m%d")
    sequence = CreditApplication.where("created_at >= ?", Date.today.beginning_of_day).count + 1
    self.application_number = "APP-#{date_part}-#{sequence.to_s.rjust(6, '0')}"
  end
end
