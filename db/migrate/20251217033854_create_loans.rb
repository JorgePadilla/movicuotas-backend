class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :contract_number, null: false, index: { unique: true }
      t.string :branch_number, null: false
      t.string :status, null: false, default: 'active'
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.decimal :approved_amount, precision: 10, scale: 2, null: false
      t.decimal :down_payment_percentage, precision: 5, scale: 2, null: false
      t.decimal :down_payment_amount, precision: 10, scale: 2, null: false
      t.decimal :financed_amount, precision: 10, scale: 2, null: false
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.integer :number_of_installments, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.text :notes

      t.timestamps
    end

    add_index :loans, :branch_number
    add_index :loans, :status
  end
end
