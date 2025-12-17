class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :phone_model, null: false, foreign_key: true
      t.string :imei, null: false, index: { unique: true }
      t.string :brand, null: false
      t.string :model, null: false
      t.string :color
      t.string :lock_status, default: 'unlocked'
      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users }
      t.text :notes

      t.timestamps
    end

    add_index :devices, :lock_status
  end
end
