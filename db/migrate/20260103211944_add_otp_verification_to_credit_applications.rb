class AddOtpVerificationToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :credit_applications, :otp_code, :string
    add_column :credit_applications, :otp_sent_at, :datetime
    add_column :credit_applications, :otp_verified_at, :datetime
    add_column :credit_applications, :otp_attempts, :integer, default: 0
    add_column :credit_applications, :otp_delivery_status, :string, default: "pending"

    add_index :credit_applications, :otp_delivery_status
  end
end
