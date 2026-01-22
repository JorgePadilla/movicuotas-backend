# frozen_string_literal: true

class BackfillActivationCodesForDevices < ActiveRecord::Migration[8.0]
  def up
    Device.where(activation_code: nil).find_each do |device|
      loop do
        code = SecureRandom.alphanumeric(6).upcase
        unless Device.exists?(activation_code: code)
          device.update_column(:activation_code, code)
          break
        end
      end
    end
  end

  def down
    # No rollback needed - codes can remain
  end
end
