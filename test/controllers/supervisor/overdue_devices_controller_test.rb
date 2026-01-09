# frozen_string_literal: true

require "test_helper"

module Supervisor
  class OverdueDevicesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @supervisor = users(:supervisor)
      @admin = users(:admin)
      @supervisor = users(:supervisor)
    end

    test "supervisor can view overdue devices list" do
      sign_in_as(@supervisor)
      get supervisor_overdue_devices_path
      assert_response :success
      assert_select "h1", "Dispositivos en Mora"
    end

    test "overdue devices list applies filters correctly" do
      sign_in_as(@supervisor)
      get supervisor_overdue_devices_path, params: { min_days: 7, min_amount: 1000 }
      assert_response :success
      # Verify filters are applied
      assert_equal 7, assigns(:min_days)
      assert_equal 1000.0, assigns(:min_amount)
    end

    test "supervisor can view device detail" do
      sign_in_as(@supervisor)
      device = devices(:with_overdue_loan)
      get supervisor_overdue_device_path(device)
      assert_response :success
      assert_select "h1", "Detalle del Dispositivo en Mora"
    end

    test "supervisor can access block confirmation page" do
      sign_in_as(@supervisor)
      device = devices(:unlocked_with_overdue_loan)
      get supervisor_overdue_device_block_path(device)
      assert_response :success
      assert_select "h1", "Confirmar Bloqueo de Dispositivo"
    end

    test "supervisor cannot block already locked device" do
      sign_in_as(@supervisor)
      device = devices(:locked)
      get supervisor_overdue_device_block_path(device)
      assert_response :redirect
      assert_equal "Este dispositivo ya está bloqueado o en proceso de bloqueo.", flash[:alert]
    end

    test "supervisor can confirm device block" do
      sign_in_as(@supervisor)
      device = devices(:unlocked_with_overdue_loan)
      assert_no_changes -> { device.reload.lock_status == "pending" } do
        post supervisor_overdue_device_confirm_block_path(device)
      end
      assert_response :redirect
      device.reload
      assert device.pending?
    end

    test "supervisor cannot block devices" do
      sign_in_as(@supervisor)
      device = devices(:unlocked_with_overdue_loan)
      get supervisor_overdue_device_block_path(device)
      assert_response :redirect
    end
  end
end
