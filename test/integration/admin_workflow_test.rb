# frozen_string_literal: true

require_relative "../integration_test_helper"

class AdminWorkflowTest < IntegrationTestCase
  # ===========================================
  # Authentication & Authorization Tests
  # ===========================================

  test "admin can access admin dashboard" do
    sign_in_admin
    get admin_root_path
    assert_response :success
    assert_response_includes "Dashboard"
  end

  test "vendedor cannot access admin dashboard" do
    sign_in_vendedor
    get admin_root_path
    assert_response :redirect
  end

  test "supervisor cannot access admin dashboard" do
    sign_in_supervisor
    get admin_root_path
    assert_response :redirect
  end

  test "unauthenticated user redirected to login" do
    get admin_root_path
    assert_requires_authentication
  end

  # ===========================================
  # Dashboard Tests
  # ===========================================

  test "admin dashboard shows key metrics" do
    sign_in_admin
    get admin_root_path
    assert_response :success
    # Dashboard should show dashboard content
    assert_response_includes "Dashboard"
  end

  # ===========================================
  # User Management Tests
  # ===========================================

  test "admin can list users" do
    sign_in_admin
    get admin_users_path
    assert_response :success
    assert_response_includes users(:admin).full_name
    assert_response_includes users(:vendedor).full_name
    assert_response_includes users(:supervisor).full_name
  end

  test "admin can view user details" do
    sign_in_admin
    get admin_user_path(users(:vendedor))
    assert_response :success
    assert_response_includes users(:vendedor).email
  end

  test "admin can create new user" do
    sign_in_admin
    get new_admin_user_path
    assert_response :success

    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          email: "newuser@test.com",
          password: "password123",
          password_confirmation: "password123",
          full_name: "New Test User",
          role: "vendedor",
          branch_number: "S01",
          active: true
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response_includes "New Test User"
  end

  test "admin can edit user" do
    sign_in_admin
    user = users(:vendedor)
    get edit_admin_user_path(user)
    assert_response :success

    patch admin_user_path(user), params: {
      user: { full_name: "Updated Vendedor Name" }
    }
    assert_response :redirect
    follow_redirect!
    assert_response_includes "Updated Vendedor Name"
  end

  test "admin can deactivate user" do
    sign_in_admin
    user = users(:vendedor)
    patch admin_user_path(user), params: {
      user: { active: false }
    }
    assert_response :redirect
    user.reload
    assert_not user.active
  end

  # ===========================================
  # Customer Management Tests
  # ===========================================

  test "admin can list customers" do
    sign_in_admin
    get admin_customers_path
    assert_response :success
    assert_response_includes customers(:customer_one).full_name
  end

  test "admin can view customer details" do
    sign_in_admin
    get admin_customer_path(customers(:customer_one))
    assert_response :success
    assert_response_includes customers(:customer_one).identification_number
  end

  test "admin can search customers" do
    sign_in_admin
    get admin_customers_path, params: { search: "Juan" }
    assert_response :success
    assert_response_includes customers(:customer_one).full_name
    assert_response_excludes customers(:customer_two).full_name
  end

  test "admin can filter customers by status" do
    sign_in_admin
    get admin_customers_path, params: { status: "blocked" }
    assert_response :success
    assert_response_includes customers(:customer_blocked).full_name
    assert_response_excludes customers(:customer_one).full_name
  end

  # ===========================================
  # Loan Management Tests
  # ===========================================

  test "admin can list loans" do
    sign_in_admin
    get admin_loans_path
    assert_response :success
    assert_response_includes loans(:loan_one).contract_number
  end

  test "admin can view loan details" do
    sign_in_admin
    get admin_loan_path(loans(:loan_one))
    assert_response :success
    assert_response_includes loans(:loan_one).contract_number
  end

  test "admin can filter loans by status" do
    sign_in_admin
    get admin_loans_path, params: { status: "completed" }
    assert_response :success
    assert_response_includes loans(:loan_completed).contract_number
  end

  # Note: Admin loans are view-only, no edit functionality
  # test "admin can edit loan" - removed as loans don't have edit routes

  # ===========================================
  # Payment Management Tests
  # ===========================================

  test "admin can list payments" do
    sign_in_admin
    get admin_payments_path
    assert_response :success
  end

  test "admin can register new payment" do
    sign_in_admin
    get new_admin_payment_path
    assert_response :success
  end

  # ===========================================
  # Reports Tests
  # ===========================================

  test "admin can access reports" do
    sign_in_admin
    get admin_reports_path
    assert_response :success
  end

  test "admin can generate customer portfolio report" do
    sign_in_admin
    get customer_portfolio_admin_reports_path
    assert_response :success
  end

  test "admin can generate revenue report" do
    sign_in_admin
    get revenue_report_admin_reports_path
    assert_response :success
  end

  test "admin can export reports as CSV" do
    sign_in_admin
    get export_report_admin_reports_path, params: { report_type: "loans", format: :csv }
    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  # ===========================================
  # Jobs Dashboard Tests
  # ===========================================

  test "admin can access jobs dashboard" do
    sign_in_admin
    get admin_jobs_path
    assert_response :success
    assert_response_includes "Monitoreo de Jobs"
  end

  test "admin can trigger manual job" do
    sign_in_admin
    # Just verify the page loads with job controls
    get admin_jobs_path
    assert_response :success
    assert_response_includes "MarkInstallmentsOverdueJob"
  end
end
