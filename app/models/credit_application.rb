class CreditApplication < ApplicationRecord
  # Available device colors
  DEVICE_COLORS = [
    "Negro",
    "Blanco",
    "Azul",
    "Rojo",
    "Verde",
    "Gris",
    "Plata",
    "Oro",
    "Rosa",
    "Morado",
    "Amarillo",
    "Naranja"
  ].freeze

  # Associations
  belongs_to :customer
  belongs_to :vendor, class_name: "User", optional: true
  belongs_to :selected_phone_model, class_name: "PhoneModel", optional: true
  has_one_attached :id_front_image
  has_one_attached :id_back_image
  has_one_attached :facial_verification_image

  accepts_nested_attributes_for :customer

  # Virtual attribute for validation context
  attr_accessor :updating_employment

  # Enums
  enum :employment_status, { employed: "employed", self_employed: "self_employed", unemployed: "unemployed", student: "student", retired: "retired" }, prefix: true
  enum :salary_range, { less_than_10000: "less_than_10000", range_10000_20000: "10000_20000", range_20000_30000: "20000_30000", range_30000_40000: "30000_40000", more_than_40000: "more_than_40000" }, prefix: true
  enum :verification_method, { sms: "sms", email: "email" }, prefix: true
  enum :otp_delivery_status, { pending: "pending", sent: "sent", delivered: "delivered", failed: "failed" }, prefix: :otp

  # OTP Constants
  OTP_EXPIRATION_TIME = 10.minutes
  OTP_MAX_ATTEMPTS = 5
  OTP_RESEND_COOLDOWN = 60.seconds
  # Validations
  validates :application_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validate :approved_amount_present_if_approved
  validates :employment_status, inclusion: { in: CreditApplication.employment_statuses.keys.map(&:to_s) }, allow_blank: true
  validates :salary_range, inclusion: { in: CreditApplication.salary_ranges.keys.map(&:to_s) }, allow_blank: true
  validates :verification_method, inclusion: { in: CreditApplication.verification_methods.keys.map(&:to_s) }, allow_blank: true

  # Conditional presence validations for employment data step
  validates :employment_status, presence: true, if: :updating_employment
  validates :salary_range, presence: true, if: :updating_employment
  validates :selected_imei, presence: { message: "debe ingresar el número IMEI" }, if: -> { selected_phone_model_id.present? }
  validates :selected_imei, format: { with: /\A\d{15}\z/, message: "debe tener 15 dígitos" }, allow_blank: true
  validates :selected_color, presence: { message: "debe seleccionar un color" }, if: -> { selected_phone_model_id.present? }
  validates :selected_color, inclusion: { in: DEVICE_COLORS, message: "debe ser un color válido" }, allow_blank: true
  validate :selected_phone_price_within_approved_amount, if: -> { selected_phone_model_id.present? && approved? }

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

    # Create audit log (only if approved by a user, not auto-approval)
    if approved_by
      AuditLog.log(
        approved_by,
        "credit_application_approved",
        self,
        { status: [ "pending", "approved" ], approved_amount: [ nil, approved_amount ] }
      )
    end
  end

  def reject!(reason, rejected_by = nil)
    update!(
      status: "rejected",
      rejection_reason: reason
    )

    # Create audit log (only if rejected by a user, not auto-rejection)
    if rejected_by
      AuditLog.log(
        rejected_by,
        "credit_application_rejected",
        self,
        { status: [ "pending", "rejected" ], rejection_reason: [ nil, reason ] }
      )
    end
  end

  def can_be_processed?
    pending? && id_front_image.attached? && id_back_image.attached? && facial_verification_image.attached?
  end

  def approved_amount_present_if_approved
    if approved? && approved_amount.blank?
      errors.add(:approved_amount, "debe estar presente cuando la solicitud está aprobada")
    end
  end

  def selected_phone_price_within_approved_amount
    return unless selected_phone_model_id.present? && approved_amount.present?

    if selected_phone_model.price > approved_amount
      errors.add(:selected_phone_model_id, "el precio del teléfono (#{selected_phone_model.price}) excede el monto aprobado (#{approved_amount})")
    end
  end

  # Returns human-readable salary range text
  def human_salary_range
    # Map stored value to display text (handles both old and new values)
    case salary_range
    when "less_than_10000", "less_than_10000"
      "Menos de L. 10,000"
    when "range_10000_20000", "10000_20000"
      "L. 10,000 - L. 20,000"
    when "range_20000_30000", "20000_30000"
      "L. 20,000 - L. 30,000"
    when "range_30000_40000", "30000_40000"
      "L. 30,000 - L. 40,000"
    when "more_than_40000", "more_than_40000"
      "Más de L. 40,000"
    else
      salary_range.to_s.humanize
    end
  end

  # OTP Methods

  # Generates a new 4-digit OTP code and stores it hashed
  # Returns the raw code for sending to the customer
  def generate_otp!
    raw_code = SecureRandom.random_number(10000).to_s.rjust(4, "0")
    update!(
      otp_code: BCrypt::Password.create(raw_code),
      otp_sent_at: Time.current,
      otp_attempts: 0,
      otp_delivery_status: :pending
    )
    raw_code
  end

  # Verifies the submitted OTP code
  # Returns { success: true/false, error: symbol, attempts_remaining: integer }
  def verify_otp(submitted_code)
    return { success: false, error: :expired } if otp_expired?
    return { success: false, error: :max_attempts } if otp_max_attempts_reached?
    return { success: false, error: :no_code } if otp_code.blank?

    if BCrypt::Password.new(otp_code) == submitted_code
      update!(otp_verified_at: Time.current)
      { success: true }
    else
      increment!(:otp_attempts)
      { success: false, error: :invalid, attempts_remaining: OTP_MAX_ATTEMPTS - otp_attempts }
    end
  end

  def otp_expired?
    return true unless otp_sent_at.present?
    Time.current > (otp_sent_at + OTP_EXPIRATION_TIME)
  end

  def otp_verified?
    otp_verified_at.present?
  end

  def otp_max_attempts_reached?
    otp_attempts >= OTP_MAX_ATTEMPTS
  end

  def can_resend_otp?
    return true unless otp_sent_at.present?
    Time.current > (otp_sent_at + OTP_RESEND_COOLDOWN)
  end

  def time_until_resend
    return 0 unless otp_sent_at.present?
    remaining = (otp_sent_at + OTP_RESEND_COOLDOWN) - Time.current
    [ remaining.to_i, 0 ].max
  end

  def otp_time_remaining
    return 0 if otp_expired?
    return 0 unless otp_sent_at.present?
    ((otp_sent_at + OTP_EXPIRATION_TIME) - Time.current).to_i
  end

  private

  def generate_application_number
    max_retries = 10
    retries = 0

    while retries < max_retries
      date_part = Time.current.strftime("%Y%m%d")
      base_number = "APP-#{date_part}-"

      # Try to get an advisory lock for this date to prevent race conditions
      lock_key = Zlib.crc32(date_part) & 0x7fffffff
      lock_acquired = false

      begin
        # Try to acquire PostgreSQL advisory lock
        # Using sanitize_sql to prevent SQL injection (lock_key is an integer from Zlib.crc32)
        sql = ActiveRecord::Base.sanitize_sql_array([ "SELECT pg_try_advisory_lock(?) as locked", lock_key ])
        result = ActiveRecord::Base.connection.select_one(sql)
        lock_acquired = result["locked"] if result
      rescue => e
        Rails.logger.warn "Could not use advisory lock: #{e.message}"
      end

      sequence = nil

      if lock_acquired
        begin
          # Get the highest sequence number for today
          last_number = CreditApplication
            .where("application_number LIKE ?", "#{base_number}%")
            .order(application_number: :desc)
            .limit(1)
            .pluck(:application_number)
            .first

          if last_number && last_number.start_with?(base_number)
            # Extract sequence part (last 6 digits)
            seq_str = last_number[base_number.length..-1]
            current_seq = seq_str.to_i
            sequence = current_seq + 1 if current_seq > 0
          end

          # If no sequence found or extraction failed, count records from today
          unless sequence
            sequence = CreditApplication.where("created_at >= ?", Time.current.beginning_of_day).count + 1
          end

          # Ensure sequence is at least 1
          sequence = 1 if sequence < 1

          self.application_number = "#{base_number}#{sequence.to_s.rjust(6, '0')}"
        ensure
          # Using sanitize_sql to prevent SQL injection
          unlock_sql = ActiveRecord::Base.sanitize_sql_array([ "SELECT pg_advisory_unlock(?)", lock_key ])
          ActiveRecord::Base.connection.execute(unlock_sql)
        end
      else
        # Fallback without lock: use timestamp with microseconds
        timestamp = Time.current.strftime("%Y%m%d-%H%M%S-%6N")
        random_suffix = SecureRandom.hex(2).upcase
        self.application_number = "APP-#{timestamp}-#{random_suffix}"
      end

      # Double-check uniqueness
      unless CreditApplication.where(application_number: application_number).exists?
        Rails.logger.info "Generated application number: #{application_number}"
        return
      end

      # If we get here, the number already exists (should be rare with lock)
      retries += 1
      Rails.logger.warn "Duplicate application number #{application_number}, retry #{retries}/#{max_retries}"
      sleep(0.1 * retries)
    end

    # Last resort: use timestamp with random component
    self.application_number = "APP-#{Time.current.strftime('%Y%m%d-%H%M%S-%6N')}-#{SecureRandom.hex(4).upcase}"
    Rails.logger.error "Used fallback application number after #{max_retries} retries: #{application_number}"
  end
end
