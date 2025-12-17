class CreateCreditApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_applications do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :vendor, foreign_key: { to_table: :users }
      t.string :application_number, null: false, index: { unique: true }
      t.string :status, null: false, default: 'pending'
      t.decimal :approved_amount, precision: 10, scale: 2
      t.string :rejection_reason
      t.string :employment_status
      t.string :salary_range
      t.string :verification_method
      t.string :id_front_image_filename
      t.string :id_back_image_filename
      t.string :facial_verification_image_filename
      t.text :notes

      t.timestamps
    end

    add_index :credit_applications, :status
  end
end
