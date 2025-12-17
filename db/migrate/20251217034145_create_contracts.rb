class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :loan, null: false, foreign_key: true, index: false
      t.string :contract_document_filename
      t.string :signature_image_filename
      t.datetime :signed_at
      t.string :signed_by_name
      t.text :notes

      t.timestamps
    end

    add_index :contracts, :loan_id, unique: true
  end
end
