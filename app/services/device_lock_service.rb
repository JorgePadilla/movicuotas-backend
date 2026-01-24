class DeviceLockService
  class << self
    def lock!(device, user, reason: "Overdue payment")
      return { success: false, error: "Device already locked or pending" } unless device.unlocked?

      state = DeviceLockState.create!(
        device: device,
        status: "pending",
        reason: reason,
        initiated_by: user,
        initiated_at: Time.current
      )

      { success: true, state: state }
    end

    def confirm_lock!(device, user = nil)
      return { success: false, error: "Device not pending" } unless device.pending?

      current_state = device.current_lock_state

      state = DeviceLockState.create!(
        device: device,
        status: "locked",
        reason: current_state&.reason,
        initiated_by: current_state&.initiated_by,
        confirmed_by: user || current_state&.initiated_by,
        initiated_at: current_state&.initiated_at,
        confirmed_at: Time.current
      )

      { success: true, state: state }
    end

    def unlock!(device, user, reason: "Payment received")
      return { success: false, error: "Device not locked" } unless device.locked?

      state = DeviceLockState.create!(
        device: device,
        status: "unlocked",
        reason: reason,
        initiated_by: user,
        initiated_at: Time.current,
        confirmed_at: Time.current
      )

      { success: true, state: state }
    end

    def current_state(device)
      device.lock_states.order(created_at: :desc).first
    end

    def history(device)
      device.lock_states.order(created_at: :desc)
    end
  end
end
