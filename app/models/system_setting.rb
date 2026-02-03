# frozen_string_literal: true

class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # Retrieve a setting value by key
  # Returns nil if the key doesn't exist
  def self.get(key)
    find_by(key: key)&.value
  end

  # Set a setting value by key
  # Creates the record if it doesn't exist, updates if it does
  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value)
    setting
  end
end
