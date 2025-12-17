class Notification < ApplicationRecord
  # Associations
  belongs_to :customer

  # Validations
  validates :title, presence: true
  validates :body, presence: true
  validates :notification_type, presence: true, inclusion: { in: %w[payment_reminder device_lock payment_confirmation general] }

  # Enums
  enum :notification_type, { payment_reminder: 'payment_reminder', device_lock: 'device_lock', payment_confirmation: 'payment_confirmation', general: 'general' }, default: 'general'

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :by_customer, ->(customer) { where(customer: customer) }

  # Callbacks
  before_create :set_sent_at

  # Methods
  def mark_as_read
    update(read_at: Time.current) unless read?
  end

  def read?
    read_at.present?
  end

  def unread?
    read_at.blank?
  end

  def self.send_payment_reminder(customer, installment)
    create!(
      customer: customer,
      title: "Recordatorio de pago",
      body: "Tu pago de L. #{installment.amount} vence el #{installment.due_date.strftime('%d/%m/%Y')}.",
      notification_type: 'payment_reminder',
      metadata: { installment_id: installment.id, loan_id: installment.loan_id }
    )
  end

  def self.send_device_lock_warning(customer, device, days_to_unlock = 3)
    create!(
      customer: customer,
      title: "Advertencia de bloqueo de dispositivo",
      body: "Tu dispositivo será bloqueado en #{days_to_unlock} días debido a pagos atrasados.",
      notification_type: 'device_lock',
      metadata: { device_id: device.id, days_to_unlock: days_to_unlock }
    )
  end

  def self.send_payment_confirmation(customer, payment)
    create!(
      customer: customer,
      title: "Pago confirmado",
      body: "Tu pago de L. #{payment.amount} ha sido confirmado.",
      notification_type: 'payment_confirmation',
      metadata: { payment_id: payment.id }
    )
  end

  private

  def set_sent_at
    self.sent_at = Time.current if sent_at.blank?
  end
end
