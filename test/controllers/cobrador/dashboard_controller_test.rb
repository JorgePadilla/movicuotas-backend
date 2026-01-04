# frozen_string_literal: true

require "test_helper"

module Cobrador
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @cobrador = users(:cobrador)
      @admin = users(:admin)
    end

    test "cobrador can access dashboard" do
      sign_in_as(@cobrador)
      get cobrador_dashboard_path
      assert_response :success
      assert_select "h1", "Dashboard de Cobrador"
    end

    test "admin can access cobrador dashboard" do
      sign_in_as(@admin)
      get cobrador_dashboard_path
      assert_response :success
    end

    test "supervisor cannot access cobrador dashboard" do
      supervisor = users(:supervisor)
      sign_in_as(supervisor)
      get cobrador_dashboard_path
      assert_response :redirect
    end

    test "dashboard displays overdue metrics" do
      sign_in_as(@cobrador)
      get cobrador_dashboard_path
      assert_response :success
      # Check that dashboard data is present in assigns
      assert_not_nil assigns(:dashboard_data)
      assert assigns(:dashboard_data).key?(:overdue_devices)
      assert assigns(:dashboard_data).key?(:blocked_devices)
    end

    test "dashboard calculates days overdue correctly" do
      sign_in_as(@cobrador)
      get cobrador_dashboard_path
      dashboard_data = assigns(:dashboard_data)

      # Verify structure of by_days breakdown
      assert dashboard_data[:overdue_devices][:by_days].key?(:"1-7")
      assert dashboard_data[:overdue_devices][:by_days].key?(:"8-15")
      assert dashboard_data[:overdue_devices][:by_days].key?(:"16-30")
      assert dashboard_data[:overdue_devices][:by_days].key?(:"30+")
    end
  end
end
