# frozen_string_literal: true

require "test_helper"

class IntegrationTestCase < ActionDispatch::IntegrationTest
  # Sign in a user via POST to the login endpoint
  def sign_in(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  # Sign in admin
  def sign_in_admin
    sign_in(users(:admin))
  end

  # Sign in supervisor
  def sign_in_supervisor
    sign_in(users(:supervisor))
  end

  # Sign in vendedor
  def sign_in_vendedor
    sign_in(users(:vendedor))
  end

  # Sign in vendedor from branch S02
  def sign_in_vendedor_s02
    sign_in(users(:vendedor_s02))
  end

  # Sign out
  def sign_out
    delete logout_path
    follow_redirect! if response.redirect?
  end

  # Assert response contains text
  def assert_response_includes(text)
    assert_includes response.body, text
  end

  # Assert response does not contain text
  def assert_response_excludes(text)
    assert_not_includes response.body, text
  end

  # Assert redirected to login
  def assert_requires_authentication
    assert_redirected_to login_path
  end

  # ===========================================
  # API Helper Methods
  # ===========================================

  # Generate JWT token for a customer (for API tests)
  def generate_customer_token(customer)
    payload = {
      customer_id: customer.id,
      exp: 30.days.from_now.to_i,
      iat: Time.now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  # Generate expired JWT token for a customer
  def generate_expired_customer_token(customer)
    payload = {
      customer_id: customer.id,
      exp: 1.day.ago.to_i,
      iat: 2.days.ago.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  # Get API headers with valid JWT token
  def api_headers(customer)
    {
      "Authorization" => "Bearer #{generate_customer_token(customer)}",
      "Content-Type" => "application/json"
    }
  end

  # Get API headers with expired token
  def api_headers_expired(customer)
    {
      "Authorization" => "Bearer #{generate_expired_customer_token(customer)}",
      "Content-Type" => "application/json"
    }
  end

  # Get API headers with invalid token
  def api_headers_invalid
    {
      "Authorization" => "Bearer invalid_token_here",
      "Content-Type" => "application/json"
    }
  end

  # Get API headers with no token
  def api_headers_no_token
    {
      "Content-Type" => "application/json"
    }
  end

  # Assert API returns unauthorized
  def assert_api_unauthorized
    assert_response :unauthorized
    data = JSON.parse(response.body)
    assert data["error"].present?
  end

  # Assert API returns success and parse response
  def assert_api_success
    assert_response :success
    JSON.parse(response.body)
  end

  # Assert API returns not found
  def assert_api_not_found
    assert_response :not_found
    data = JSON.parse(response.body)
    assert data["error"].present?
  end

  # Parse API response body
  def api_response
    JSON.parse(response.body)
  end
end
