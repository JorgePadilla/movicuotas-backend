class CreateDefaultQrCode < ActiveRecord::Migration[8.1]
  def change
    create_table :default_qr_codes do |t|
      t.string :qr_code_filename
      t.datetime :qr_code_uploaded_at
      t.integer :qr_code_uploaded_by_id
      t.timestamps
    end

    add_foreign_key :default_qr_codes, :users, column: :qr_code_uploaded_by_id
  end
end
