class MdmBlueprint < ApplicationRecord
  # Associations
  belongs_to :device
  has_one_attached :qr_code_image

  # Validations
  validates :device, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active inactive expired] }

  # Enums
  enum :status, { active: 'active', inactive: 'inactive', expired: 'expired' }, default: 'active'

  # Callbacks
  before_validation :generate_qr_code_data, if: -> { qr_code_data.blank? }
  after_create :generate_qr_code_image

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
    # This would call a service to generate QR code image
    # QrCodeGeneratorService.new(qr_code_data).generate
    # For now, we'll just set a placeholder
    self.generated_at = Time.current
    save
  end

  def expired?
    status == 'expired' || (generated_at && generated_at < 30.days.ago)
  end

  def mark_as_expired
    update(status: 'expired')
  end

  private
end
