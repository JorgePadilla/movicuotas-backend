# frozen_string_literal: true

class AddDeviceIdToDeviceTokens < ActiveRecord::Migration[8.0]
  def change
    add_reference :device_tokens, :device, foreign_key: true
  end
end
