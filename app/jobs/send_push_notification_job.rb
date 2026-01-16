# frozen_string_literal: true

# Job to send a push notification via FCM
# Can be called directly or as a callback from Notification model
#
# Usage:
#   SendPushNotificationJob.perform_later(notification_id: notification.id)
#
class SendPushNotificationJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  # Retry on transient errors
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(notification_id:)
    notification = Notification.find(notification_id)

    # Skip if already delivered or failed permanently
    return if notification.status.in?(%w[delivered failed_permanent])

    # Skip if FCM not configured
    unless FcmService.configured?
      notification.update(status: "skipped", error_message: "FCM not configured")
      return
    end

    customer = notification.customer
    unless customer
      notification.update(status: "failed_permanent", error_message: "No customer associated")
      return
    end

    # Send via FCM
    result = FcmService.send_to_customer(
      customer,
      title: notification.title,
      body: notification.body,
      data: build_data_payload(notification),
      notification_type: notification.notification_type
    )

    # Update notification status
    if result[:success]
      notification.update(
        status: "delivered",
        sent_at: Time.current,
        delivery_method: "fcm"
      )
      Rails.logger.info("[FCM] Notification #{notification.id} delivered to customer #{customer.id}")
    else
      handle_failure(notification, result)
    end
  end

  private

  def build_data_payload(notification)
    payload = {
      notification_id: notification.id.to_s,
      notification_type: notification.notification_type,
      click_action: "OPEN_NOTIFICATION"
    }

    # Add metadata if present
    if notification.metadata.present?
      metadata = notification.metadata.is_a?(String) ? JSON.parse(notification.metadata) : notification.metadata
      payload.merge!(metadata.transform_keys(&:to_s))
    end

    # Add data field if present
    if notification.data.present?
      data = notification.data.is_a?(String) ? JSON.parse(notification.data) : notification.data
      payload.merge!(data.transform_keys(&:to_s))
    end

    payload
  rescue JSON::ParserError
    { notification_id: notification.id.to_s, notification_type: notification.notification_type }
  end

  def handle_failure(notification, result)
    error_code = result[:error_code]
    error_message = result[:error]

    case error_code
    when "UNREGISTERED", "INVALID_ARGUMENT"
      # Permanent failure - don't retry
      notification.update(
        status: "failed_permanent",
        error_message: "#{error_code}: #{error_message}"
      )
      Rails.logger.warn("[FCM] Notification #{notification.id} failed permanently: #{error_message}")
    when "QUOTA_EXCEEDED"
      # Transient - will be retried
      notification.update(
        status: "pending",
        error_message: "Rate limited, will retry"
      )
      Rails.logger.warn("[FCM] Notification #{notification.id} rate limited, will retry")
      raise "FCM rate limited" # Trigger retry
    else
      # Unknown error - retry a few times then give up
      notification.update(
        status: "failed",
        error_message: "#{error_code}: #{error_message}"
      )
      Rails.logger.error("[FCM] Notification #{notification.id} failed: #{error_message}")
    end
  end
end
