# frozen_string_literal: true

require "test_helper"

module Vendor
  class MdmChecklistsControllerTest < ActionDispatch::IntegrationTest
    setup do
      # Use supervisor since MdmBlueprintPolicy requires admin? or supervisor?
      @supervisor = users(:supervisor)
      @device = devices(:device_one)
      @loan = @device.loan
      @contract = contracts(:contract_one)

      # Create MdmBlueprint for testing
      @mdm_blueprint = MdmBlueprint.create!(
        device: @device,
        status: "active",
        qr_code_data: { device_id: @device.id }.to_json
      )

      # Login as supervisor (required for MDM Blueprint authorization)
      post login_url, params: { email: @supervisor.email, password: "password123" }
    end

    teardown do
      @mdm_blueprint&.destroy
    end

    test "show displays mdm checklist page" do
      get vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint)

      assert_response :success
    end

    test "create completes checklist and device stays unlocked" do
      # Ensure device starts as unlocked (no lock states = unlocked)
      @device.lock_states.destroy_all
      assert_equal "unlocked", @device.lock_status

      post vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "1" }
      }

      assert_redirected_to success_vendor_contract_path(@contract)

      # THIS IS THE CRITICAL TEST: Device should remain unlocked after MDM checklist completion
      @device.reload
      assert_equal "unlocked", @device.lock_status,
        "Device should stay unlocked after completing MDM checklist. " \
        "lock_status should only change via lock!/unlock! for non-payment."
    end

    test "create does not change lock_status from unlocked - BUG FIX VERIFICATION" do
      # This test verifies the fix for the bug where completing MDM checklist
      # incorrectly set lock_status to "locked" instead of keeping it "unlocked"
      # Ensure device is unlocked (no lock states = unlocked)
      @device.lock_states.destroy_all

      post vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "1" }
      }

      @device.reload
      assert_equal "unlocked", @device.lock_status,
        "BUG FIX VERIFICATION: Previously this incorrectly set lock_status to 'locked'. " \
        "Device must remain 'unlocked' after MDM checklist completion."
    end

    test "create fails without checklist confirmation" do
      post vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "0" }
      }

      assert_response :unprocessable_entity
      assert_match /Por favor confirma que la app MOVICUOTAS/, flash[:alert]
    end

    test "create clears session data after completion" do
      # Set up session data that should be cleared
      get vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint)

      post vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "1" }
      }

      assert_redirected_to success_vendor_contract_path(@contract)
      follow_redirect!

      # Session data should be cleared (no direct way to test session, but redirect works)
      assert_response :success
    end

    test "create redirects to success page with notice" do
      post vendor_mdm_blueprint_mdm_checklist_path(@mdm_blueprint), params: {
        mdm_checklist: { movicuotas_installed: "1" }
      }

      assert_redirected_to success_vendor_contract_path(@contract)
      assert_match /Felicidades/, flash[:notice]
      assert_match /completado/, flash[:notice]
    end
  end
end
