# frozen_string_literal: true

require "test_helper"

class DeviceLockStateTest < ActiveSupport::TestCase
  setup do
    @device = devices(:device_one)
    @admin = users(:admin)
    @supervisor = users(:supervisor)
  end

  test "valid device lock state" do
    state = DeviceLockState.new(
      device: @device,
      status: "pending",
      reason: "Test reason",
      initiated_by: @admin,
      initiated_at: Time.current
    )
    assert state.valid?
  end

  test "requires device" do
    state = DeviceLockState.new(
      status: "pending",
      reason: "Test reason"
    )
    assert_not state.valid?
    # Error message is in Spanish (locale)
    assert state.errors[:device_id].present?
  end

  test "requires status" do
    state = DeviceLockState.new(
      device: @device,
      reason: "Test reason"
    )
    # Status has a default value, so it should be valid
    assert state.valid?
    assert_equal "unlocked", state.status
  end

  test "status enum values" do
    state = DeviceLockState.new(device: @device)

    state.status = "unlocked"
    assert state.unlocked?

    state.status = "pending"
    assert state.pending?

    state.status = "locked"
    assert state.locked?
  end

  test "belongs to device" do
    state = DeviceLockState.create!(
      device: @device,
      status: "pending",
      reason: "Test",
      initiated_by: @admin,
      initiated_at: Time.current
    )
    assert_equal @device, state.device
  end

  test "belongs to initiated_by user" do
    state = DeviceLockState.create!(
      device: @device,
      status: "pending",
      reason: "Test",
      initiated_by: @admin,
      initiated_at: Time.current
    )
    assert_equal @admin, state.initiated_by
  end

  test "belongs to confirmed_by user" do
    state = DeviceLockState.create!(
      device: @device,
      status: "locked",
      reason: "Test",
      initiated_by: @admin,
      confirmed_by: @supervisor,
      initiated_at: 1.hour.ago,
      confirmed_at: Time.current
    )
    assert_equal @supervisor, state.confirmed_by
  end

  test "scope current returns most recent state" do
    # Clean up existing states for this device
    @device.lock_states.destroy_all

    older = DeviceLockState.create!(
      device: @device,
      status: "pending",
      reason: "Older",
      initiated_by: @admin,
      initiated_at: 2.hours.ago,
      created_at: 2.hours.ago
    )

    newer = DeviceLockState.create!(
      device: @device,
      status: "locked",
      reason: "Newer",
      initiated_by: @admin,
      initiated_at: 1.hour.ago,
      created_at: 1.hour.ago
    )

    current = @device.lock_states.current.first
    assert_equal newer, current
  end

  test "scope locked_states returns only locked states" do
    @device.lock_states.destroy_all

    DeviceLockState.create!(
      device: @device,
      status: "pending",
      reason: "Pending",
      initiated_by: @admin,
      initiated_at: Time.current
    )

    locked = DeviceLockState.create!(
      device: @device,
      status: "locked",
      reason: "Locked",
      initiated_by: @admin,
      initiated_at: Time.current
    )

    locked_states = DeviceLockState.locked_states
    assert_includes locked_states, locked
    assert_equal 1, locked_states.where(device: @device).count
  end

  test "creates audit log on create when initiated_by is present" do
    @device.lock_states.destroy_all

    assert_difference "AuditLog.count", 1 do
      DeviceLockState.create!(
        device: @device,
        status: "pending",
        reason: "Test audit",
        initiated_by: @admin,
        initiated_at: Time.current
      )
    end

    audit_log = AuditLog.last
    assert_equal @admin, audit_log.user
    assert_equal "device_lock_state_changed", audit_log.action
    assert_equal @device, audit_log.resource
  end

  test "does not create audit log when initiated_by is nil" do
    @device.lock_states.destroy_all

    assert_no_difference "AuditLog.count" do
      DeviceLockState.create!(
        device: @device,
        status: "unlocked",
        reason: "Initial state"
      )
    end
  end
end
