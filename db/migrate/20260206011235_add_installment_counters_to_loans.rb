class AddInstallmentCountersToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :paid_installments_count, :integer, default: 0, null: false
    add_column :loans, :overdue_installments_count, :integer, default: 0, null: false
    add_column :loans, :next_due_date, :date

    add_index :loans, :next_due_date
  end
end
