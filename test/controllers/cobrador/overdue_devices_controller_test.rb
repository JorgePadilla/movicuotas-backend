# frozen_string_literal: true

require "test_helper"

module Cobrador
  class OverdueDevicesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @cobrador = users(:cobrador)
      @admin = users(:admin)
      @vendedor = users(:vendedor)
    end

    test "cobrador can view overdue devices list" do
      sign_in_as(@cobrador)
      get cobrador_overdue_devices_path
      assert_response :success
      assert_select "h1", "Dispositivos en Mora"
    end

    test "overdue devices list applies filters correctly" do
      sign_in_as(@cobrador)
      get cobrador_overdue_devices_path, params: { min_days: 7, min_amount: 1000 }
      assert_response :success
      # Verify filters are applied
      assert_equal 7, assigns(:min_days)
      assert_equal 1000.0, assigns(:min_amount)
    end

    test "cobrador can view device detail" do
      sign_in_as(@cobrador)
      device = devices(:with_overdue_loan)
      get cobrador_overdue_device_path(device)
      assert_response :success
      assert_select "h1", "Detalle del Dispositivo en Mora"
    end

    test "cobrador can access block confirmation page" do
      sign_in_as(@cobrador)
      device = devices(:unlocked_with_overdue_loan)
      get cobrador_overdue_device_block_path(device)
      assert_response :success
      assert_select "h1", "Confirmar Bloqueo de Dispositivo"
    end

    test "cobrador cannot block already locked device" do
      sign_in_as(@cobrador)
      device = devices(:locked)
      get cobrador_overdue_device_block_path(device)
      assert_response :redirect
      assert_equal "Este dispositivo ya está bloqueado o en proceso de bloqueo.", flash[:alert]
    end

    test "cobrador can confirm device block" do
      sign_in_as(@cobrador)
      device = devices(:unlocked_with_overdue_loan)
      assert_no_changes -> { device.reload.lock_status == "pending" } do
        post cobrador_overdue_device_confirm_block_path(device)
      end
      assert_response :redirect
      device.reload
      assert device.pending?
    end

    test "vendedor cannot block devices" do
      sign_in_as(@vendedor)
      device = devices(:unlocked_with_overdue_loan)
      get cobrador_overdue_device_block_path(device)
      assert_response :redirect
    end
  end
end
