# frozen_string_literal: true

class NotifyCobradoresJob < ApplicationJob
  queue_as :notifications
  set_priority :high

  def perform
    Rails.logger.info("NotifyCobradoresJob: Starting")
  end
end
