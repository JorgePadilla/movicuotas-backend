class AddNotifiedAtToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :notified_at, :datetime
  end
end
