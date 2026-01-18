# frozen_string_literal: true

# Configure Mission Control Jobs
# Authentication is handled by route constraints in routes.rb
MissionControl::Jobs.http_basic_auth_enabled = false

# Use ActionController::Base instead of ApplicationController to avoid Pundit
MissionControl::Jobs.base_controller_class = "ActionController::Base"
