class RemoveFilenameColumnsFromCreditApplications < ActiveRecord::Migration[8.1]
  def up
    remove_column :credit_applications, :id_front_image_filename
    remove_column :credit_applications, :id_back_image_filename
    remove_column :credit_applications, :facial_verification_image_filename
  end

  def down
    add_column :credit_applications, :id_front_image_filename, :string
    add_column :credit_applications, :id_back_image_filename, :string
    add_column :credit_applications, :facial_verification_image_filename, :string
  end
end
