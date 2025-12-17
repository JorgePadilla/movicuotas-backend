class AddUserToLoans < ActiveRecord::Migration[8.1]
  def change
    add_reference :loans, :user, null: true, foreign_key: true
  end
end
