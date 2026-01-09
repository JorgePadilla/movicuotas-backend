# frozen_string_literal: true

class MdmBlockService
  def initialize(device, user)
    @device = device
    @user = user
    @reason = "Overdue payment"
  end

  def block!
    return { error: "Unauthorized" } unless can_block?
    return { error: "Already blocked" } if @device.locked?

    ActiveRecord::Base.transaction do
      # Update device status to pending
      @device.lock!(@user, @reason)

      # Create audit log (already done in Device#lock!)
      # Queue MDM blocking job
      MdmBlockDeviceJob.perform_later(@device.id) if defined?(MdmBlockDeviceJob)

      # Notify customer
      notify_customer if @device.loan&.customer.present?
    end

    { success: true, message: "Dispositivo marcado para bloqueo" }
  end

  private

  def can_block?
    @user.admin? || @user.supervisor?
  end

  def notify_customer
    # Notification service would be called here
    customer = @device.loan.customer
    # NotificationService.send_device_lock_warning(customer, days_to_unlock: 3)
  end
end
