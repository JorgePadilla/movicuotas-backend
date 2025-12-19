class MakeLoanIdOptionalOnDevices < ActiveRecord::Migration[8.1]
  def change
    change_column_null :devices, :loan_id, true
  end
end
