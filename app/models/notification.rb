class Notification < ApplicationRecord
  # Associations
  belongs_to :customer

  # Alias body to message for API compatibility
  # Schema uses 'message' column, but 'body' is used in FCM/notification APIs
  alias_attribute :body, :message

  # Serialize metadata as JSON (column is TEXT)
  serialize :metadata, coder: JSON

  # Validations
  validates :title, presence: true
  validates :notification_type, presence: true
  validates :message, presence: true

  # Enums
  enum :notification_type, {
    payment_reminder: "payment_reminder",
    device_lock: "device_lock",
    payment_confirmation: "payment_confirmation",
    overdue_warning: "overdue_warning",
    device_blocking_alert: "device_blocking_alert",
    contract_signed: "contract_signed",
    general: "general"
  }, default: "general"

  enum :status, {
    pending: "pending",
    delivered: "delivered",
    failed: "failed",
    failed_permanent: "failed_permanent",
    skipped: "skipped"
  }, default: "pending", prefix: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :by_customer, ->(customer) { where(customer: customer) }
  scope :pending_delivery, -> { where(status: "pending") }

  # Callbacks
  before_create :set_sent_at
  after_create_commit :queue_push_notification

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
      notification_type: "payment_reminder",
      metadata: { installment_id: installment.id, loan_id: installment.loan_id }
    )
  end

  def self.send_device_lock_warning(customer, device, days_to_unlock = 3)
    create!(
      customer: customer,
      title: "Advertencia de bloqueo de dispositivo",
      body: "Tu dispositivo será bloqueado en #{days_to_unlock} días debido a pagos atrasados.",
      notification_type: "device_lock",
      metadata: { device_id: device.id, days_to_unlock: days_to_unlock }
    )
  end

  def self.send_payment_confirmation(customer, payment)
    create!(
      customer: customer,
      title: "Pago confirmado",
      body: "Tu pago de L. #{payment.amount} ha sido confirmado.",
      notification_type: "payment_confirmation",
      metadata: { payment_id: payment.id }
    )
  end

  def self.send_overdue_warning(customer, installment, days_overdue)
    create!(
      customer: customer,
      title: "Pago atrasado",
      body: "Tienes un pago atrasado de #{days_overdue} días. Por favor realiza tu pago lo antes posible.",
      notification_type: "overdue_warning",
      metadata: { installment_id: installment&.id, days_overdue: days_overdue }
    )
  end

  # Get the notification body content
  def content
    message
  end

  private

  def set_sent_at
    self.sent_at = Time.current if sent_at.blank?
  end

  def queue_push_notification
    return unless delivery_method == "fcm" || delivery_method.nil?
    return if status_delivered? || status_skipped?

    SendPushNotificationJob.perform_later(notification_id: id)
  end
end
