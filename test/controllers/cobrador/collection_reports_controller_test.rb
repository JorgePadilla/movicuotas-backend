# frozen_string_literal: true

require "test_helper"

module Cobrador
  class CollectionReportsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @cobrador = users(:cobrador)
      @admin = users(:admin)
      @vendedor = users(:vendedor)
    end

    test "cobrador can view collection reports" do
      sign_in_as(@cobrador)
      get cobrador_collection_reports_path
      assert_response :success
      assert_select "h1", "Reportes de Mora"
    end

    test "admin can view collection reports" do
      sign_in_as(@admin)
      get cobrador_collection_reports_path
      assert_response :success
    end

    test "vendedor cannot view collection reports" do
      sign_in_as(@vendedor)
      get cobrador_collection_reports_path
      assert_response :redirect
    end

    test "collection reports displays summary metrics" do
      sign_in_as(@cobrador)
      get cobrador_collection_reports_path

      report_data = assigns(:report_data)
      assert report_data.key?(:summary)
      assert report_data[:summary].key?(:total_overdue_count)
      assert report_data[:summary].key?(:total_overdue_amount)
      assert report_data[:summary].key?(:devices_blocked)
      assert report_data[:summary].key?(:devices_at_risk)
    end

    test "collection reports displays breakdown by days" do
      sign_in_as(@cobrador)
      get cobrador_collection_reports_path

      by_days = assigns(:report_data)[:by_days]
      assert by_days.key?(:"1-7 días")
      assert by_days.key?(:"8-15 días")
      assert by_days.key?(:"16-30 días")
      assert by_days.key?(:"30+ días")
    end

    test "collection reports filters by date range" do
      sign_in_as(@cobrador)
      start_date = 30.days.ago.to_date
      end_date = Date.today

      get cobrador_collection_reports_path, params: {
        start_date: start_date,
        end_date: end_date
      }

      assert_response :success
      assert_equal start_date, assigns(:date_range).begin
      assert_equal end_date, assigns(:date_range).end
    end

    test "collection reports uses default 30-day range when not specified" do
      sign_in_as(@cobrador)
      get cobrador_collection_reports_path

      date_range = assigns(:date_range)
      assert_equal (30.days.ago.to_date), date_range.begin
      assert_equal Date.today, date_range.end
    end

    test "collection reports includes recovery rate calculation" do
      sign_in_as(@cobrador)
      get cobrador_collection_reports_path

      recovery_rate = assigns(:report_data)[:recovery_rate]
      assert_kind_of Numeric, recovery_rate
      assert recovery_rate >= 0
    end
  end
end
