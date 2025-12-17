class CreatePaymentInstallments < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_installments do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :installment, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :payment_installments, [:payment_id, :installment_id], unique: true
  end
end
