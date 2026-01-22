class MdmBlueprint < ApplicationRecord
  # Associations
  belongs_to :device
  has_one_attached :qr_code_image

  # Validations
  validates :device, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active inactive expired] }

  # Enums
  enum :status, { active: "active", inactive: "inactive", expired: "expired" }, default: "active"

  # Callbacks
  before_validation :generate_qr_code_data, if: -> { qr_code_data.blank? }
  after_commit :generate_qr_code_image, on: :create

  # Methods
  def generate_qr_code_data
    # Generate MDM configuration data for the device
    self.qr_code_data = {
      device_id: device.id,
      imei: device.imei,
      loan_id: device.loan_id,
      customer_id: device.loan.customer_id,
      configuration_url: "#{ENV['MDM_BASE_URL']}/configure/#{device.id}",
      timestamp: Time.current.iso8601
    }.to_json
  end

  def generate_qr_code_image
    return if qr_code_data.blank?

    # Generate QR code and attach to ActiveStorage attachment
    service = QrCodeGeneratorService.new(qr_code_data, fill: "#125282", background: "#ffffff")
    success = service.attach_to(qr_code_image, format: :png)

    if success
      self.generated_at = Time.current
      save
    else
      Rails.logger.error "Failed to generate QR code image for MdmBlueprint #{id}"
    end
  end

  def expired?
    status == "expired" || (generated_at && generated_at < 30.days.ago)
  end

  def mark_as_expired
    update(status: "expired")
  end

  private
end
