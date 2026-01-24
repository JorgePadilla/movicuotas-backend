# frozen_string_literal: true

require "test_helper"

class DeviceLockServiceTest < ActiveSupport::TestCase
  setup do
    @device = devices(:device_one)
    @admin = users(:admin)
    @supervisor = users(:supervisor)
    # Ensure device starts as unlocked
    @device.lock_states.destroy_all
  end

  # ============================================
  # lock! tests
  # ============================================

  test "lock! creates pending lock state for unlocked device" do
    result = DeviceLockService.lock!(@device, @admin, reason: "Overdue payment")

    assert result[:success]
    assert_not_nil result[:state]
    assert_equal "pending", result[:state].status
    assert_equal "Overdue payment", result[:state].reason
    assert_equal @admin, result[:state].initiated_by
    assert_not_nil result[:state].initiated_at
  end

  test "lock! fails for already pending device" do
    DeviceLockService.lock!(@device, @admin)

    result = DeviceLockService.lock!(@device, @supervisor)

    assert_not result[:success]
    assert_equal "Device already locked or pending", result[:error]
  end

  test "lock! fails for already locked device" do
    DeviceLockService.lock!(@device, @admin)
    DeviceLockService.confirm_lock!(@device, @admin)

    result = DeviceLockService.lock!(@device, @supervisor)

    assert_not result[:success]
    assert_equal "Device already locked or pending", result[:error]
  end

  test "lock! uses default reason when not provided" do
    result = DeviceLockService.lock!(@device, @admin)

    assert result[:success]
    assert_equal "Overdue payment", result[:state].reason
  end

  # ============================================
  # confirm_lock! tests
  # ============================================

  test "confirm_lock! creates locked state for pending device" do
    DeviceLockService.lock!(@device, @admin, reason: "Test lock")

    result = DeviceLockService.confirm_lock!(@device, @supervisor)

    assert result[:success]
    assert_not_nil result[:state]
    assert_equal "locked", result[:state].status
    assert_equal "Test lock", result[:state].reason
    assert_equal @admin, result[:state].initiated_by
    assert_equal @supervisor, result[:state].confirmed_by
    assert_not_nil result[:state].confirmed_at
  end

  test "confirm_lock! fails for unlocked device" do
    result = DeviceLockService.confirm_lock!(@device)

    assert_not result[:success]
    assert_equal "Device not pending", result[:error]
  end

  test "confirm_lock! fails for already locked device" do
    DeviceLockService.lock!(@device, @admin)
    DeviceLockService.confirm_lock!(@device, @admin)

    result = DeviceLockService.confirm_lock!(@device, @supervisor)

    assert_not result[:success]
    assert_equal "Device not pending", result[:error]
  end

  test "confirm_lock! uses initiated_by as confirmed_by when not specified" do
    DeviceLockService.lock!(@device, @admin)

    result = DeviceLockService.confirm_lock!(@device)

    assert result[:success]
    assert_equal @admin, result[:state].confirmed_by
  end

  # ============================================
  # unlock! tests
  # ============================================

  test "unlock! creates unlocked state for locked device" do
    DeviceLockService.lock!(@device, @admin)
    DeviceLockService.confirm_lock!(@device, @admin)

    result = DeviceLockService.unlock!(@device, @supervisor, reason: "Payment received")

    assert result[:success]
    assert_not_nil result[:state]
    assert_equal "unlocked", result[:state].status
    assert_equal "Payment received", result[:state].reason
    assert_equal @supervisor, result[:state].initiated_by
    assert_not_nil result[:state].confirmed_at
  end

  test "unlock! fails for unlocked device" do
    result = DeviceLockService.unlock!(@device, @admin)

    assert_not result[:success]
    assert_equal "Device not locked", result[:error]
  end

  test "unlock! fails for pending device" do
    DeviceLockService.lock!(@device, @admin)

    result = DeviceLockService.unlock!(@device, @supervisor)

    assert_not result[:success]
    assert_equal "Device not locked", result[:error]
  end

  test "unlock! uses default reason when not provided" do
    DeviceLockService.lock!(@device, @admin)
    DeviceLockService.confirm_lock!(@device, @admin)

    result = DeviceLockService.unlock!(@device, @supervisor)

    assert result[:success]
    assert_equal "Payment received", result[:state].reason
  end

  # ============================================
  # current_state tests
  # ============================================

  test "current_state returns most recent lock state" do
    DeviceLockService.lock!(@device, @admin)

    state = DeviceLockService.current_state(@device)

    assert_equal "pending", state.status
  end

  test "current_state returns nil for device with no states" do
    state = DeviceLockService.current_state(@device)

    assert_nil state
  end

  # ============================================
  # history tests
  # ============================================

  test "history returns all lock states in reverse chronological order" do
    DeviceLockService.lock!(@device, @admin, reason: "First lock")
    DeviceLockService.confirm_lock!(@device, @admin)
    DeviceLockService.unlock!(@device, @supervisor, reason: "First unlock")
    DeviceLockService.lock!(@device, @admin, reason: "Second lock")

    history = DeviceLockService.history(@device)

    assert_equal 4, history.count
    assert_equal "pending", history.first.status # Most recent
    assert_equal "Second lock", history.first.reason
  end

  # ============================================
  # Integration with Device model tests
  # ============================================

  test "device.lock_status returns current state status" do
    assert_equal "unlocked", @device.lock_status

    DeviceLockService.lock!(@device, @admin)
    assert_equal "pending", @device.lock_status

    DeviceLockService.confirm_lock!(@device, @admin)
    assert_equal "locked", @device.lock_status

    DeviceLockService.unlock!(@device, @supervisor)
    assert_equal "unlocked", @device.lock_status
  end

  test "device.locked? returns true only when locked" do
    assert_not @device.locked?

    DeviceLockService.lock!(@device, @admin)
    assert_not @device.locked?

    DeviceLockService.confirm_lock!(@device, @admin)
    assert @device.locked?
  end

  test "device.pending? returns true only when pending" do
    assert_not @device.pending?

    DeviceLockService.lock!(@device, @admin)
    assert @device.pending?

    DeviceLockService.confirm_lock!(@device, @admin)
    assert_not @device.pending?
  end

  test "device.unlocked? returns true when no states or unlocked" do
    assert @device.unlocked?

    DeviceLockService.lock!(@device, @admin)
    assert_not @device.unlocked?

    DeviceLockService.confirm_lock!(@device, @admin)
    assert_not @device.unlocked?

    DeviceLockService.unlock!(@device, @supervisor)
    assert @device.unlocked?
  end

  test "device.locked_by returns initiator of current lock state" do
    assert_nil @device.locked_by

    DeviceLockService.lock!(@device, @admin)
    assert_equal @admin, @device.locked_by
  end

  test "device.locked_at returns timestamp of lock" do
    assert_nil @device.locked_at

    DeviceLockService.lock!(@device, @admin)
    assert_not_nil @device.locked_at

    DeviceLockService.confirm_lock!(@device, @admin)
    assert_not_nil @device.locked_at
  end

  # ============================================
  # Device scope tests
  # ============================================

  test "Device.locked returns only locked devices" do
    device_two = devices(:device_two)
    device_two.lock_states.destroy_all

    DeviceLockService.lock!(@device, @admin)
    DeviceLockService.confirm_lock!(@device, @admin)

    locked_devices = Device.locked

    assert_includes locked_devices, @device
    assert_not_includes locked_devices, device_two
  end

  test "Device.pending_lock returns only pending devices" do
    device_two = devices(:device_two)
    device_two.lock_states.destroy_all

    DeviceLockService.lock!(@device, @admin)

    pending_devices = Device.pending_lock

    assert_includes pending_devices, @device
    assert_not_includes pending_devices, device_two
  end

  test "Device.unlocked returns devices without lock states and with unlocked status" do
    device_two = devices(:device_two)
    device_two.lock_states.destroy_all

    DeviceLockService.lock!(@device, @admin)

    unlocked_devices = Device.unlocked

    assert_not_includes unlocked_devices, @device
    assert_includes unlocked_devices, device_two
  end
end
