# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :customer, optional: true
  belongs_to :device, optional: true

  # Validations
  validates :token, presence: true, uniqueness: true, length: { minimum: 50 }
  validates :platform, presence: true, inclusion: {
    in: %w[ios android web],
    message: "%{value} is not a valid platform"
  }
  validate :must_belong_to_user_or_customer

  # Enums
  enum :platform, {
    ios: "ios",
    android: "android",
    web: "web"
  }

  # Scopes
  scope :active, -> { where(active: true, invalidated_at: nil) }
  scope :inactive, -> { where(active: false).or(where.not(invalidated_at: nil)) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_customer, ->(customer) { where(customer: customer) }
  scope :for_device, ->(device) { where(device: device) }
  scope :recently_used, -> { order(last_used_at: :desc) }
  scope :stale, -> { where("last_used_at < ?", 90.days.ago) }

  # Callbacks
  before_create :set_active_status
  before_save :validate_token_format

  # Methods
  def mark_as_used
    update(last_used_at: Time.current)
  end

  def invalidate
    update(active: false, invalidated_at: Time.current)
  end

  def reactivate
    update(active: true, invalidated_at: nil)
  end

  def is_active?
    active && invalidated_at.nil?
  end

  def is_stale?
    last_used_at.nil? || last_used_at < 90.days.ago
  end

  def device_info
    {
      platform: platform,
      app_version: app_version,
      os_version: os_version,
      device_name: device_name,
      last_used: last_used_at&.strftime("%d/%m/%Y %H:%M")
    }
  end

  # Owner helper
  def owner
    customer || user
  end

  private

  def set_active_status
    self.active = true if active.nil?
  end

  def validate_token_format
    # FCM tokens are typically long alphanumeric strings with colons, underscores, and hyphens
    unless token.match?(/\A[a-zA-Z0-9_:\-]+\z/)
      errors.add(:token, "has an invalid format for FCM token")
    end
  end

  def must_belong_to_user_or_customer
    if user_id.blank? && customer_id.blank?
      errors.add(:base, "Device token must belong to either a user or a customer")
    end
  end
end
