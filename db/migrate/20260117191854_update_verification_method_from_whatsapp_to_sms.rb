class UpdateVerificationMethodFromWhatsappToSms < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE credit_applications
      SET verification_method = 'sms'
      WHERE verification_method = 'whatsapp'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE credit_applications
      SET verification_method = 'whatsapp'
      WHERE verification_method = 'sms'
    SQL
  end
end
