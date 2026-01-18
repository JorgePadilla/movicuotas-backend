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
end
