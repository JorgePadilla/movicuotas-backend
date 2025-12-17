class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :payment_date, null: false
      t.string :payment_method, null: false
      t.string :reference_number
      t.string :verification_status, default: 'pending'
      t.text :notes

      t.timestamps
    end

    add_index :payments, :payment_date
    add_index :payments, :verification_status
  end
end
