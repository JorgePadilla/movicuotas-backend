require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get login_url
    assert_response :success
    assert_select "h1", "MOVICUOTAS"
    assert_select "h2", "Iniciar Sesión"
    assert_select "form[action='#{login_path}']"
    assert_select "input[name='email']"
    assert_select "input[name='password'][type='password']"
  end

  test "should log in with valid credentials" do
    post login_url, params: { email: "supervisor@movicuotas.com", password: "password123" }
    assert_redirected_to vendor_customer_search_path
    follow_redirect!
    assert_response :success
    assert_equal "Sesión iniciada correctamente", flash[:notice]
    # Should have session token cookie
    assert_not_nil cookies[:session_token]
  end

  test "should not log in with invalid credentials" do
    post login_url, params: { email: "supervisor@movicuotas.com", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_equal "Email o contraseña incorrectos", flash[:alert]
    assert cookies[:session_token].blank?
  end

  test "should log out" do
    # First log in
    post login_url, params: { email: "supervisor@movicuotas.com", password: "password123" }
    session_token = cookies[:session_token]
    assert_not_nil session_token

    # Then log out
    delete logout_url
    assert_redirected_to root_path
    assert_equal "Sesión cerrada", flash[:notice]
    # After logout, cookie should be cleared (empty string)
    assert cookies[:session_token].blank?
  end

  test "should redirect to role-specific dashboard after login" do
    # Admin
    post login_url, params: { email: "admin@movicuotas.com", password: "password123" }
    assert_redirected_to admin_dashboard_path

    # Supervisor
    delete logout_url # Log out admin first
    post login_url, params: { email: "supervisor@movicuotas.com", password: "password123" }
    assert_redirected_to vendor_customer_search_path

    # Cobrador
    delete logout_url
    post login_url, params: { email: "cobrador@movicuotas.com", password: "password123" }
    assert_redirected_to cobrador_dashboard_path
  end

  test "should redirect to login if not authenticated" do
    get admin_dashboard_path
    assert_redirected_to login_path
    assert_equal "Debes iniciar sesión", flash[:alert]
  end
end
