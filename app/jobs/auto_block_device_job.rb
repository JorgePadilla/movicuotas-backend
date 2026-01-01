# frozen_string_literal: true

class AutoBlockDeviceJob < ApplicationJob
  queue_as :blocking
  set_priority :critical

  OVERDUE_THRESHOLD_DAYS = 30

  def perform
    log_execution("Starting: Auto-blocking devices with 30+ days overdue")

    blocked_count = auto_block_critical_overdue_devices
    log_execution("Completed: Auto-blocked #{blocked_count} devices", :info, { count: blocked_count })
    track_metric("devices_auto_blocked", blocked_count)
  rescue StandardError => e
    log_execution("Error auto-blocking devices: #{e.message}", :error)
    notify_error(e, { job: self.class.name })
    raise
  end

  private

  def auto_block_critical_overdue_devices
    blocked_count = 0

    # Find devices with 30+ days overdue that are not already locked/pending
    critical_devices = find_critical_overdue_devices

    critical_devices.find_each do |device|
      if block_device(device)
        blocked_count += 1
      end
    rescue StandardError => e
      log_execution("Error blocking device #{device.id}: #{e.message}", :error)
      # Continue with next device instead of failing the whole job
    end

    blocked_count
  end

  def find_critical_overdue_devices
    Device.joins(loan: :installments)
          .where(installments: { status: :overdue })
          .where("CAST(CURRENT_DATE AS date) - installments.due_date >= ?", OVERDUE_THRESHOLD_DAYS)
          .where(lock_status: [ :unlocked, nil ])
          .distinct
  end

  def block_device(device)
    return false if device.nil? || device.locked? || device.pending_lock?

    # Use system user for auto-blocking (no user interaction)
    system_user = get_or_create_system_user
    return false unless system_user

    # Use MdmBlockService which handles authorization, audit logs, and notifications
    service = MdmBlockService.new(device, system_user)
    result = service.block!

    if result[:success]
      log_execution("Auto-blocked device #{device.id} for customer #{device.loan&.customer&.id}", :info)

      # Send immediate notification to customer about blocking
      send_device_blocked_notification(device)

      true
    else
      log_execution("Failed to block device #{device.id}: #{result[:error]}", :warn)
      false
    end
  end

  def send_device_blocked_notification(device)
    return unless device.loan&.customer.present?

    customer = device.loan.customer
    overdue_installment = customer.loans.joins(:installments)
                                   .where(installments: { status: :overdue })
                                   .order("installments.due_date")
                                   .first&.installments&.first

    return unless overdue_installment.present?

    days_overdue = (Date.today - overdue_installment.due_date).to_i

    Notification.send_device_blocking_alert(customer, device, overdue_installment)
  rescue StandardError => e
    log_execution("Error sending notification for blocked device #{device.id}: #{e.message}", :error)
  end

  def get_or_create_system_user
    # Find or create a system user for automated actions
    User.find_by(email: "system@movicuotas.local") ||
      User.create(
        email: "system@movicuotas.local",
        password: SecureRandom.hex(32),
        password_confirmation: SecureRandom.hex(32),
        full_name: "Sistema MOVICUOTAS",
        role: "admin"
      )
  rescue StandardError => e
    log_execution("Error creating/finding system user: #{e.message}", :error)
    nil
  end
end
