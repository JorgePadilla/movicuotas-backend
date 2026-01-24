class DeviceLockState < ApplicationRecord
  # Associations
  belongs_to :device
  belongs_to :initiated_by, class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true

  # Enums
  enum :status, {
    unlocked: "unlocked",
    pending: "pending",
    locked: "locked"
  }, default: "unlocked"

  # Validations
  validates :status, presence: true
  validates :device_id, presence: true

  # Scopes
  scope :current, -> { order(created_at: :desc).limit(1) }
  scope :locked_states, -> { where(status: "locked") }
  scope :pending_states, -> { where(status: "pending") }

  # Callbacks
  after_create :create_audit_log

  private

  def create_audit_log
    return unless initiated_by

    AuditLog.log(
      initiated_by,
      "device_lock_state_changed",
      device,
      { status: status, reason: reason, previous_status: previous_status }
    )
  end

  def previous_status
    device.lock_states.where.not(id: id).order(created_at: :desc).first&.status
  end
end
