class CreateInstallments < ActiveRecord::Migration[8.1]
  def change
    create_table :installments, if_not_exists: true do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :installment_number, null: false
      t.date :due_date, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'
      t.date :paid_date
      t.decimal :paid_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :late_fee, precision: 10, scale: 2, default: 0.0
      t.text :notes

      t.timestamps
    end

    add_index :installments, [ :loan_id, :installment_number ], unique: true
    add_index :installments, :due_date
    add_index :installments, :status
    add_index :installments, [ :due_date, :status ]
  end
end
