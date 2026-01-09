# frozen_string_literal: true

class AddVerificationFieldsToPayments < ActiveRecord::Migration[8.1]
  def change
    # Note: reference_number already exists in the payments table

    # Bank or payment source (e.g., "BAC", "Banpais", "Tigo Money", etc.)
    add_column :payments, :bank_source, :string

    # Who verified/rejected the payment (references users table)
    add_reference :payments, :verified_by, null: true, foreign_key: { to_table: :users }

    # When the payment was verified/rejected
    add_column :payments, :verified_at, :datetime
  end
end
