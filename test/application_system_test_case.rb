# frozen_string_literal: true

require "test_helper"
require "capybara/rails"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Helper to sign in a user via the login form
  def sign_in_as(user, password: "password123")
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: password
    click_button "Iniciar Sesión"
  end

  # Helper to sign in admin
  def sign_in_admin
    sign_in_as(users(:admin))
  end

  # Helper to sign in supervisor
  def sign_in_supervisor
    sign_in_as(users(:supervisor))
  end

  # Helper to sign in vendedor
  def sign_in_vendedor
    sign_in_as(users(:vendedor))
  end

  # Assert current path
  def assert_current_path(path)
    assert_equal path, current_path
  end

  # Wait for Turbo to finish loading
  def wait_for_turbo
    sleep 0.1 # Brief pause for Turbo Drive
  end
end
