# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :user_id, presence: true, uniqueness: true
  validates :reminder_frequency, presence: true, inclusion: {
    in: %w[daily weekly never],
    message: "%{value} is not a valid reminder frequency"
  }
  validates :language, presence: true, inclusion: {
    in: %w[es en fr],
    message: "%{value} is not a supported language"
  }
  validates :max_notifications_per_day, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 50 }

  # Enums
  enum :reminder_frequency, {
    daily: "daily",
    weekly: "weekly",
    never: "never"
  }

  enum :language, {
    es: "es",
    en: "en",
    fr: "fr"
  }

  # Scopes
  scope :with_reminders_enabled, -> { where(daily_reminders: true) }
  scope :with_fcm_enabled, -> { where(receive_fcm_notifications: true) }
  scope :with_sms_enabled, -> { where(receive_sms_notifications: true) }
  scope :with_email_enabled, -> { where(receive_email_notifications: true) }

  # Callbacks
  before_create :set_defaults

  # Methods
  def can_receive_notification?(type)
    case type
    when "daily_reminder"
      daily_reminders && reminder_frequency != "never"
    when "payment_confirmation"
      payment_confirmations
    when "overdue_warning"
      overdue_warnings
    when "device_blocking_alert"
      device_blocking_alerts
    when "promotional_messages"
      promotional_messages
    else
      true
    end
  end

  def can_receive_via_method?(method)
    case method
    when "fcm", "push"
      receive_fcm_notifications
    when "sms"
      receive_sms_notifications
    when "email"
      receive_email_notifications
    else
      false
    end
  end

  def in_quiet_hours?
    return false if quiet_hours_start.nil? || quiet_hours_end.nil?

    current_time = Time.current.strftime("%H:%M").to_s
    start_time = quiet_hours_start.strftime("%H:%M").to_s
    end_time = quiet_hours_end.strftime("%H:%M").to_s

    if start_time <= end_time
      current_time >= start_time && current_time <= end_time
    else
      # Quiet hours span midnight
      current_time >= start_time || current_time <= end_time
    end
  end

  def available_channels
    channels = []
    channels << "fcm" if receive_fcm_notifications
    channels << "sms" if receive_sms_notifications
    channels << "email" if receive_email_notifications
    channels
  end

  def notification_counts_summary
    {
      daily_reminders: daily_reminders,
      payment_confirmations: payment_confirmations,
      overdue_warnings: overdue_warnings,
      device_blocking_alerts: device_blocking_alerts,
      promotional_messages: promotional_messages
    }
  end

  private

  def set_defaults
    self.daily_reminders = true if daily_reminders.nil?
    self.payment_confirmations = true if payment_confirmations.nil?
    self.overdue_warnings = true if overdue_warnings.nil?
    self.device_blocking_alerts = true if device_blocking_alerts.nil?
    self.promotional_messages = false if promotional_messages.nil?
    self.receive_fcm_notifications = true if receive_fcm_notifications.nil?
    self.receive_sms_notifications = false if receive_sms_notifications.nil?
    self.receive_email_notifications = true if receive_email_notifications.nil?
    self.language = "es" if language.nil?
    self.reminder_frequency = "daily" if reminder_frequency.nil?
    self.max_notifications_per_day = 10 if max_notifications_per_day.nil?
  end
end
