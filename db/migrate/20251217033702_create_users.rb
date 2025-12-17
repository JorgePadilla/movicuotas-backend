class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, if_not_exists: true do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :full_name, null: false
      t.string :role, null: false, default: 'vendedor'
      t.string :branch_number  # For vendors and cobradores
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
