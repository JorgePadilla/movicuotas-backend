class Contract < ApplicationRecord
  # Associations
  belongs_to :loan, optional: true
  has_one_attached :contract_document
  has_one_attached :signature_image

  # Validations
  validates :loan, uniqueness: true, allow_nil: true

  # Callbacks
  before_save :set_signed_at, if: -> { signature_image.attached? && signed_at.blank? }

  # Methods
  def signed?
    signature_image.attached? && signed_at.present?
  end

  def sign!(signature_image_file, signed_by_name = nil, user = nil)
    puts "DEBUG Contract#sign! called with file: #{signature_image_file.class.name}, size: #{signature_image_file.size rescue 'unknown'}"
    Rails.logger.warn "DEBUG Contract#sign! called with file: #{signature_image_file.class.name}, size: #{signature_image_file.size rescue 'unknown'}"
    Rails.logger.info "Contract#sign! called with file: #{signature_image_file.class.name}, size: #{signature_image_file.size rescue 'unknown'}"

    transaction do
      # Handle different file types for ActiveStorage attachment
      if signature_image_file.is_a?(Tempfile)
        # Tempfile from base64 decoded signature
        signature_image.attach(
          io: signature_image_file,
          filename: "signature_#{Time.current.to_i}.png",
          content_type: 'image/png'
        )
      elsif signature_image_file.respond_to?(:original_filename) && signature_image_file.respond_to?(:content_type)
        # ActionDispatch::Http::UploadedFile or similar
        signature_image.attach(signature_image_file)
      else
        # Fallback to direct attach (for other attachable types)
        signature_image.attach(signature_image_file)
      end

      self.signed_by_name = signed_by_name if signed_by_name
      self.signed_at = Time.current
      save!

      # Audit log (doesn't affect return value)
      AuditLog.log(user || User.system_user, 'contract_signed', self, {
        signed_by_name: signed_by_name,
        signed_at: signed_at,
        loan_id: loan_id
      }) if Rails.env.production? || Rails.env.development?

      true  # Return truthy value on success
    end
  rescue => e
    Rails.logger.error "Contract#sign! failed: #{e.class.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
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
