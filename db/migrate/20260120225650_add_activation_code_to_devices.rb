# frozen_string_literal: true

class AddActivationCodeToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :activation_code, :string, limit: 8
    add_column :devices, :activated_at, :datetime
    add_index :devices, :activation_code, unique: true
  end
end
