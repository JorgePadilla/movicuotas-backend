# frozen_string_literal: true

# Job to send a test push notification to all customers with active device tokens
# Used for testing FCM integration
#
# Usage:
#   SendTestNotificationJob.perform_later
#
class SendTestNotificationJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  def perform
    unless FcmService.configured?
      log_execution("FCM not configured - skipping test notification", :warn)
      return { success: false, error: "FCM not configured" }
    end

    log_execution("Starting: Test notification to all devices")

    # Get all customers with active device tokens
    customers_with_tokens = Customer.joins(:device_tokens)
                                    .where(device_tokens: { active: true })
                                    .distinct

    total = customers_with_tokens.count
    success_count = 0
    failed_count = 0

    customers_with_tokens.find_each do |customer|
      begin
        result = FcmService.send_to_customer(
          customer,
          title: "Prueba de Notificación",
          body: "Esta es una notificación de prueba de MOVICUOTAS. Si recibes esto, las notificaciones funcionan correctamente.",
          data: { type: "test", timestamp: Time.current.to_i.to_s },
          notification_type: "test"
        )

        if result[:success]
          success_count += 1
        else
          failed_count += 1
          log_execution("Failed to send to customer #{customer.id}: #{result[:error]}", :warn)
        end
      rescue StandardError => e
        failed_count += 1
        log_execution("Error sending to customer #{customer.id}: #{e.message}", :error)
      end
    end

    log_execution("Completed: #{success_count}/#{total} successful, #{failed_count} failed", :info)

    {
      success: true,
      total: total,
      successful: success_count,
      failed: failed_count
    }
  end
end
