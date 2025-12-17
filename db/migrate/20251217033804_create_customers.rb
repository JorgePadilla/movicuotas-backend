class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :identification_number, null: false, index: { unique: true }
      t.string :full_name, null: false
      t.string :gender
      t.date :date_of_birth, null: false
      t.text :address
      t.string :city
      t.string :department
      t.string :phone, null: false
      t.string :email
      t.string :status, default: 'active'
      t.text :notes

      t.timestamps
    end
  end
end
