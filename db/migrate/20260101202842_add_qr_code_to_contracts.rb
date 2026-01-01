class AddQrCodeToContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :contracts, :qr_code_filename, :string
    add_column :contracts, :qr_code_uploaded_at, :datetime
    add_column :contracts, :qr_code_uploaded_by_id, :integer
    add_foreign_key :contracts, :users, column: :qr_code_uploaded_by_id
  end
end
