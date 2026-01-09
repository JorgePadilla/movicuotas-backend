# frozen_string_literal: true

require "test_helper"

class MdmBlockServiceTest < ActiveSupport::TestCase
  setup do
    @supervisor = users(:supervisor)
    @admin = users(:admin)
    @vendedor = users(:vendedor)
    @device = devices(:device_one)
  end

  test "supervisor can block device" do
    service = MdmBlockService.new(@device, @supervisor)
    result = service.block!

    assert result[:success]
    assert_equal "Dispositivo marcado para bloqueo", result[:message]
  end

  test "admin can block device" do
    service = MdmBlockService.new(@device, @admin)
    result = service.block!

    assert result[:success]
  end

  test "vendedor cannot block device" do
    service = MdmBlockService.new(@device, @vendedor)
    result = service.block!

    assert_equal "Unauthorized", result[:error]
  end

  test "device status changes to pending after block" do
    service = MdmBlockService.new(@device, @supervisor)
    service.block!

    @device.reload
    assert @device.pending?
    assert_not_nil @device.locked_at
  end

  test "cannot block already locked device" do
    @device.update(lock_status: "locked")
    service = MdmBlockService.new(@device, @supervisor)
    result = service.block!

    assert_equal "Already blocked", result[:error]
  end

  test "audit log is created when device is blocked" do
    service = MdmBlockService.new(@device, @supervisor)
    assert_difference "AuditLog.count", 1 do
      service.block!
    end

    audit_log = AuditLog.last
    assert_equal @supervisor, audit_log.user
    assert_equal "device_lock_requested", audit_log.action
  end

  test "locked_by user is set correctly" do
    service = MdmBlockService.new(@device, @supervisor)
    service.block!

    @device.reload
    assert_equal @supervisor, @device.locked_by
  end
end
