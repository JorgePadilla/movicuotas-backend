class AddDownPaymentCollectionFieldsToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :down_payment_method, :string
    add_column :loans, :down_payment_confirmed_at, :datetime
    add_column :loans, :down_payment_confirmed_by_id, :bigint
    add_column :loans, :down_payment_verification_status, :string
    add_column :loans, :down_payment_rejection_reason, :text

    add_index :loans, :down_payment_verification_status
    add_foreign_key :loans, :users, column: :down_payment_confirmed_by_id
  end
end
