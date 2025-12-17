class Device < ApplicationRecord
  # Associations
  belongs_to :loan
  belongs_to :phone_model
  belongs_to :locked_by, class_name: 'User', optional: true
  has_one :mdm_blueprint, dependent: :destroy

  # Validations
  validates :imei, presence: true, uniqueness: true,
            format: { with: /\A\d{15}\z/, message: "debe tener 15 dígitos" },
            length: { is: 15 }
  validates :brand, presence: true
  validates :model, presence: true
  validates :lock_status, presence: true, inclusion: { in: %w[unlocked pending locked] }

  # Enums
  enum :lock_status, { unlocked: 'unlocked', pending: 'pending', locked: 'locked' }, default: 'unlocked'

  # Scopes
  scope :locked, -> { where(lock_status: 'locked') }
  scope :pending_lock, -> { where(lock_status: 'pending') }
  scope :unlocked, -> { where(lock_status: 'unlocked') }
  scope :with_overdue_loans, -> { joins(loan: :installments).where(installments: { status: 'overdue' }).distinct }

  # Callbacks
  after_update :broadcast_status_change, if: -> { saved_change_to_lock_status? }

  # Methods
  def lock!(locked_by_user, reason = "Overdue payment")
    return false unless unlocked?

    update!(
      lock_status: 'pending',
      locked_by: locked_by_user,
      locked_at: Time.current
    )

    # Create audit log
    AuditLog.create!(
      user: locked_by_user,
      action: 'device_lock_requested',
      resource: self,
      changes: {
        reason: reason,
        lock_status: ['unlocked', 'pending']
      }
    )

    true
  end

  def confirm_lock!
    return false unless pending?
    update!(lock_status: 'locked')
  end

  def unlock!(unlocked_by_user, reason = "Payment received")
    return false unless locked?

    update!(
      lock_status: 'unlocked',
      locked_by: nil,
      locked_at: nil
    )

    # Create audit log
    AuditLog.create!(
      user: unlocked_by_user,
      action: 'device_unlocked',
      resource: self,
      changes: {
        reason: reason,
        lock_status: ['locked', 'unlocked']
      }
    )

    true
  end

  def locked?
    lock_status == 'locked'
  end

  def pending?
    lock_status == 'pending'
  end

  def unlocked?
    lock_status == 'unlocked'
  end

  private

  def broadcast_status_change
    # This would be used for Turbo Stream broadcasting
    # BroadcastReplaceJob.perform_later(self, "device_#{id}_status")
  end
end
