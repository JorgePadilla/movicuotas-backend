class CreateMdmBlueprints < ActiveRecord::Migration[8.1]
  def change
    create_table :mdm_blueprints do |t|
      t.references :device, null: false, foreign_key: true, index: false
      t.text :qr_code_data
      t.string :qr_code_image_filename
      t.string :status, default: 'active'
      t.datetime :generated_at

      t.timestamps
    end

    add_index :mdm_blueprints, :device_id, unique: true
    add_index :mdm_blueprints, :status
  end
end
