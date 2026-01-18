# frozen_string_literal: true

class DefaultQrCode < ApplicationRecord
  # Associations
  belongs_to :qr_code_uploaded_by, class_name: "User", optional: true
  has_one_attached :qr_code

  # Methods
  def qr_code_present?
    qr_code.attached?
  end

  def upload_qr_code!(qr_code_file, uploaded_by_user)
    transaction do
      # Handle different file types for ActiveStorage attachment
      if qr_code_file.is_a?(Tempfile)
        qr_code.attach(
          io: qr_code_file,
          filename: "default_qr_code_#{Time.current.to_i}.png",
          content_type: "image/png"
        )
      elsif qr_code_file.respond_to?(:original_filename) && qr_code_file.respond_to?(:content_type)
        # ActionDispatch::Http::UploadedFile or similar
        qr_code.attach(qr_code_file)
      else
        # Fallback to direct attach (for other attachable types)
        qr_code.attach(qr_code_file)
      end

      self.qr_code_uploaded_by = uploaded_by_user
      self.qr_code_uploaded_at = Time.current
      save!

      # Audit log
      AuditLog.log(uploaded_by_user || User.system_user, "default_qr_code_uploaded", self, {
        qr_code_filename: qr_code.filename,
        qr_code_uploaded_at: qr_code_uploaded_at
      }) if Rails.env.production? || Rails.env.development?

      true  # Return truthy value on success
    end
  rescue => e
    Rails.logger.error "DefaultQrCode#upload_qr_code! failed: #{e.class.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  # Class method to get or create the default QR code
  def self.default
    find_or_create_by(id: 1)
  end
end
