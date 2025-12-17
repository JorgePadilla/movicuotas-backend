class Contract < ApplicationRecord
  # Associations
  belongs_to :loan
  has_one_attached :contract_document
  has_one_attached :signature_image

  # Validations
  validates :loan, presence: true, uniqueness: true

  # Callbacks
  before_save :set_signed_at, if: -> { signature_image.attached? && signed_at.blank? }

  # Methods
  def signed?
    signature_image.attached? && signed_at.present?
  end

  def sign!(signature_image_file, signed_by_name = nil)
    transaction do
      self.signature_image.attach(signature_image_file)
      self.signed_by_name = signed_by_name if signed_by_name
      self.signed_at = Time.current
      save!
    end
  end

  def generate_pdf
    # This would call a service to generate PDF contract
    # ContractGeneratorService.new(self).generate
    # For now, return a placeholder
    "PDF contract content for loan #{loan.contract_number}"
  end

  private

  def set_signed_at
    self.signed_at = Time.current if signature_image.attached?
  end
end
