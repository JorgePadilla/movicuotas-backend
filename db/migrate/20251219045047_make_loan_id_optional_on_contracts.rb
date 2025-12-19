class MakeLoanIdOptionalOnContracts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :contracts, :loan_id, true
  end
end
