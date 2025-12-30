class AddSelectedPhoneFieldsToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :credit_applications, :selected_phone_model_id, :bigint
    add_column :credit_applications, :selected_imei, :string
    add_column :credit_applications, :selected_color, :string

    add_foreign_key :credit_applications, :phone_models, column: :selected_phone_model_id
    add_index :credit_applications, :selected_phone_model_id
  end
end
