# frozen_string_literal: true

require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  # ===========================================
  # LOGIN PAGE TESTS
  # ===========================================

  test "login page loads correctly" do
    visit login_path

    # h1 has brand name, h2 has "Iniciar Sesión"
    assert_selector "h1", text: "MOVICUOTAS"
    assert_selector "h2", text: "Iniciar Sesión"
    assert_selector "input[name='email']"
    assert_selector "input[name='password']"
    assert_selector "input[type='submit']"
  end

  test "login page shows MOVICUOTAS branding" do
    visit login_path

    assert_text "MOVICUOTAS"
    assert_text "Tu Crédito, Tu Móvil"
  end

  # ===========================================
  # SUCCESSFUL LOGIN TESTS
  # ===========================================

  test "admin can login successfully" do
    admin = users(:admin)

    visit login_path
    fill_in "email", with: admin.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Admin should be redirected to admin dashboard
    assert_text "Dashboard"
  end

  test "supervisor can login successfully" do
    supervisor = users(:supervisor)

    visit login_path
    fill_in "email", with: supervisor.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Supervisor should be redirected to supervisor dashboard
    assert_text "Dashboard"
  end

  test "vendedor can login successfully" do
    vendedor = users(:vendedor)

    visit login_path
    fill_in "email", with: vendedor.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Vendedor should be redirected to vendor section (customer search)
    assert_text "Buscar Cliente"
  end

  # ===========================================
  # FAILED LOGIN TESTS
  # ===========================================

  test "login fails with invalid email" do
    visit login_path
    fill_in "email", with: "invalid@email.com"
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Should stay on login page (flash message or form shown again)
    assert_selector "input[name='email']"
  end

  test "login fails with invalid password" do
    admin = users(:admin)

    visit login_path
    fill_in "email", with: admin.email
    fill_in "password", with: "wrongpassword"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Should stay on login page
    assert_selector "input[name='email']"
  end

  test "login fails with empty credentials" do
    visit login_path
    click_button "Iniciar Sesión"

    # Should stay on login page (HTML5 validation may prevent submit)
    assert_selector "input[name='email']"
  end

  test "login fails for inactive user" do
    # Create an inactive user
    inactive_user = User.create!(
      email: "inactive_test_#{SecureRandom.hex(4)}@movicuotas.com",
      password: "password123",
      full_name: "Inactive User",
      role: "vendedor",
      branch_number: "S01",
      active: false
    )

    visit login_path
    fill_in "email", with: inactive_user.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Should stay on login page - inactive users cannot login
    assert_selector "input[name='email']"

    # Cleanup
    inactive_user.destroy
  end

  # ===========================================
  # LOGOUT TESTS
  # ===========================================

  test "user can logout" do
    sign_in_admin

    # Look for logout in various forms
    if page.has_link?("Cerrar Sesión")
      click_link "Cerrar Sesión"
    elsif page.has_button?("Cerrar Sesión")
      click_button "Cerrar Sesión"
    elsif page.has_css?("a[href='#{logout_path}']")
      find("a[href='#{logout_path}']").click
    else
      # Try finding dropdown menu first
      find("button[data-dropdown-toggle]").click if page.has_css?("button[data-dropdown-toggle]")
      sleep 0.5
      click_link "Cerrar Sesión" if page.has_link?("Cerrar Sesión")
    end

    wait_for_turbo
    # Should be redirected to login page
    assert_selector "input[name='email']"
  end

  # ===========================================
  # SESSION PERSISTENCE TESTS
  # ===========================================

  test "user remains logged in when navigating" do
    sign_in_admin

    # Navigate to different pages
    visit admin_users_path
    assert_no_selector "h2", text: "Iniciar Sesión"

    visit admin_customers_path
    assert_no_selector "h2", text: "Iniciar Sesión"

    visit admin_loans_path
    assert_no_selector "h2", text: "Iniciar Sesión"
  end

  # ===========================================
  # REDIRECT AFTER LOGIN TESTS
  # ===========================================

  test "admin redirected to admin dashboard after login" do
    admin = users(:admin)

    visit login_path
    wait_for_turbo

    fill_in "email", with: admin.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Admin root redirects to dashboard - check for admin path or dashboard content
    assert(
      current_path.start_with?("/admin") ||
      page.has_content?("Dashboard") ||
      page.has_content?("Administración"),
      "Admin should be redirected to admin section after login"
    )
  end

  test "vendedor redirected to vendor section after login" do
    vendedor = users(:vendedor)

    visit login_path
    wait_for_turbo

    fill_in "email", with: vendedor.email
    fill_in "password", with: "password123"
    click_button "Iniciar Sesión"

    wait_for_turbo
    # Vendedor should go to customer search (vendor root) - check for vendor path or content
    assert(
      current_path.start_with?("/vendor") ||
      page.has_content?("Buscar Cliente") ||
      page.has_content?("Dashboard"),
      "Vendedor should be redirected to vendor section after login"
    )
  end

  # ===========================================
  # PROTECTED ROUTES REDIRECT TO LOGIN
  # ===========================================

  test "unauthenticated user redirected to login from admin routes" do
    visit admin_root_path

    wait_for_turbo
    # Should be redirected to login
    assert_selector "input[name='email']"
  end

  test "unauthenticated user redirected to login from vendor routes" do
    visit vendor_root_path

    wait_for_turbo
    # Should be redirected to login
    assert_selector "input[name='email']"
  end

  test "unauthenticated user redirected to login from supervisor routes" do
    visit supervisor_dashboard_path

    wait_for_turbo
    # Should be redirected to login
    assert_selector "input[name='email']"
  end

  # ===========================================
  # PASSWORD RESET LINK
  # ===========================================

  test "login page has forgot password link" do
    visit login_path

    # The actual link text from the view
    assert_link "¿Olvidaste tu contraseña?"
  end

  test "forgot password link leads to password reset page" do
    visit login_path
    click_link "¿Olvidaste tu contraseña?"

    wait_for_turbo
    # Should be on password reset page
    assert_selector "input[name='email']"
  end
end
