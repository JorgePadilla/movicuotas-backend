# frozen_string_literal: true

class AddCreditApplicationToLoans < ActiveRecord::Migration[8.1]
  def up
    add_reference :loans, :credit_application, null: true, foreign_key: true

    # Backfill: Link existing loans to credit applications via customer
    # Find the most recent approved credit application for each loan's customer
    Loan.includes(:customer, :device).find_each do |loan|
      next unless loan.customer

      credit_app = CreditApplication.where(customer: loan.customer, status: "approved")
                                    .order(created_at: :desc)
                                    .first

      if credit_app
        loan.update_column(:credit_application_id, credit_app.id)

        # Also create device if missing and credit application has phone data
        if loan.device.nil? && credit_app.selected_phone_model_id && credit_app.selected_imei
          phone_model = PhoneModel.find_by(id: credit_app.selected_phone_model_id)
          if phone_model
            # Check if IMEI already exists
            existing_device = Device.find_by(imei: credit_app.selected_imei)
            if existing_device
              puts "IMEI #{credit_app.selected_imei} already exists for device #{existing_device.id}, skipping loan #{loan.id}"
              next
            end

            begin
              device = Device.new(
                loan: loan,
                phone_model: phone_model,
                imei: credit_app.selected_imei,
                brand: phone_model.brand,
                model: phone_model.model,
                color: credit_app.selected_color || phone_model.color || "Negro",
                lock_status: "unlocked"
              )

              if device.save
                device.create_mdm_blueprint!
                puts "Created device #{device.id} with activation code #{device.activation_code} for loan #{loan.id}"
              else
                puts "Failed to create device for loan #{loan.id}: #{device.errors.full_messages.join(', ')}"
              end
            rescue => e
              puts "Error creating device for loan #{loan.id}: #{e.message}"
            end
          end
        end
      end
    end
  end

  def down
    remove_reference :loans, :credit_application
  end
end
