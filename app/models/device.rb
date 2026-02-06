class Device < ApplicationRecord
  # Associations
  belongs_to :loan, optional: true
  belongs_to :phone_model
  has_one :mdm_blueprint, dependent: :destroy
  has_many :device_tokens, dependent: :nullify
  has_many :lock_states, class_name: "DeviceLockState", dependent: :destroy

  # Validations
  validates :imei, presence: true, uniqueness: true,
            format: { with: /\A\d{15}\z/, message: "debe tener 15 dígitos" }
  validates :brand, presence: true
  validates :model, presence: true

  # Scopes - using subqueries for current lock state
  scope :locked, -> {
    where(id: DeviceLockState.select(:device_id)
      .where("device_lock_states.id = (SELECT MAX(id) FROM device_lock_states dls WHERE dls.device_id = device_lock_states.device_id)")
      .where(status: "locked"))
  }

  scope :pending_lock, -> {
    where(id: DeviceLockState.select(:device_id)
      .where("device_lock_states.id = (SELECT MAX(id) FROM device_lock_states dls WHERE dls.device_id = device_lock_states.device_id)")
      .where(status: "pending"))
  }

  scope :unlocked, -> {
    left_joins(:lock_states)
      .where(device_lock_states: { id: nil })
      .or(
        where(id: DeviceLockState.select(:device_id)
          .where("device_lock_states.id = (SELECT MAX(id) FROM device_lock_states dls WHERE dls.device_id = device_lock_states.device_id)")
          .where(status: "unlocked"))
      )
      .distinct
  }

  scope :with_overdue_loans, -> { joins(loan: :installments).where(installments: { status: "overdue" }).distinct }

  # Callbacks
  before_create :generate_activation_code

  # Lock state delegation methods (for backward compatibility)
  def current_lock_state
    lock_states.order(created_at: :desc).first
  end

  def lock_status
    current_lock_state&.status || "unlocked"
  end

  def locked_by
    current_lock_state&.initiated_by
  end

  def locked_by_id
    current_lock_state&.initiated_by_id
  end

  def locked_at
    current_lock_state&.confirmed_at || current_lock_state&.initiated_at
  end

  def locked?
    lock_status == "locked"
  end

  def pending?
    lock_status == "pending"
  end

  def unlocked?
    lock_status == "unlocked"
  end

  # Lock methods delegating to DeviceLockService (for backward compatibility)
  def lock!(user, reason = "Pago vencido")
    result = DeviceLockService.lock!(self, user, reason: reason)
    result[:success]
  end

  def confirm_lock!(user = nil)
    result = DeviceLockService.confirm_lock!(self, user)
    result[:success]
  end

  def unlock!(user, reason = "Pago recibido")
    result = DeviceLockService.unlock!(self, user, reason: reason)
    result[:success]
  end

  # Activation methods
  def activate!
    update!(activated_at: Time.current)
  end

  def activated?
    activated_at.present?
  end

  def reset_activation!(user)
    return false unless activated?

    update!(activated_at: nil)

    # Clear any existing device tokens for this device
    device_tokens.destroy_all

    # Create audit log
    AuditLog.log(
      user,
      "device_activation_reset",
      self,
      { activation_code: activation_code, previous_activated_at: activated_at_before_last_save }
    )

    true
  end

  private

  def generate_activation_code
    return if activation_code.present?

    loop do
      self.activation_code = SecureRandom.alphanumeric(6).upcase
      break unless Device.exists?(activation_code: activation_code)
    end
  end
end
