class CreatePhoneModels < ActiveRecord::Migration[8.1]
  def change
    create_table :phone_models do |t|
      t.string :brand, null: false
      t.string :model, null: false
      t.string :storage
      t.string :color
      t.decimal :price, precision: 10, scale: 2, null: false
      t.boolean :active, default: true
      t.string :image_url

      t.timestamps
    end

    add_index :phone_models, [:brand, :model], unique: true
  end
end
