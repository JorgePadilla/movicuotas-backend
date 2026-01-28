# app/controllers/vendor/device_selections_controller.rb
module Vendor
  class DeviceSelectionsController < ApplicationController
    include ActionView::Helpers::NumberHelper

    before_action :set_credit_application
    before_action :authorize_credit_application
    before_action :ensure_device_selected, only: [ :confirmation ]

    # Age-based maximum financing amounts
    MAX_FINANCING_SENIOR = 3000  # 50-60 years
    MAX_FINANCING_STANDARD = 3500  # 21-49 years

    # Step 10: Catálogo Teléfonos (Device Selection)
    # GET /vendor/device_selection/:credit_application_id
    def show
      max_price = max_financing_amount_for_customer
      @phone_models = PhoneModel.active.where("price <= ?", max_price).order(:brand, :model)
      @max_financing_amount = max_price
    end

    # Step 10: Process device selection
    # PATCH /vendor/device_selection/:credit_application_id
    def update
      # Validate selected phone is within customer's max financing amount
      max_price = max_financing_amount_for_customer
      selected_phone = PhoneModel.find_by(id: device_selection_params[:selected_phone_model_id])

      if selected_phone && selected_phone.price > max_price
        @phone_models = PhoneModel.active.where("price <= ?", max_price).order(:brand, :model)
        @max_financing_amount = max_price
        flash.now[:alert] = "El teléfono seleccionado excede el monto máximo de financiamiento (L. #{number_with_delimiter(max_price)})."
        render :show, status: :unprocessable_entity
        return
      end

      if @credit_application.update(device_selection_params)
        redirect_to vendor_device_selection_confirmation_path(@credit_application),
                    notice: "Teléfono seleccionado correctamente. Proceda a confirmación."
      else
        @phone_models = PhoneModel.active.where("price <= ?", max_price).order(:brand, :model)
        @max_financing_amount = max_price
        flash.now[:alert] = "Error al seleccionar el teléfono. Verifique los datos."
        render :show, status: :unprocessable_entity
      end
    end

    # Step 11: Confirmación (Purchase Summary)
    # GET /vendor/device_selections/:credit_application_id/confirmation
    def confirmation
      # @credit_application already loaded with selected_phone_model
      @max_financing_amount = max_financing_amount_for_customer
    end

    private

    def set_credit_application
      @credit_application = CreditApplication.find(params[:credit_application_id])
    end

    def authorize_credit_application
      authorize @credit_application
      # Additional validation: credit application must be approved
      unless @credit_application.approved?
        redirect_to vendor_customer_search_path,
                    alert: "Esta solicitud de crédito no está aprobada."
      end
    end

    def ensure_device_selected
      unless @credit_application.selected_phone_model_id.present?
        redirect_to vendor_device_selection_path(@credit_application),
                    alert: "Primero debe seleccionar un teléfono."
      end
    end

    def device_selection_params
      params.require(:credit_application).permit(
        :selected_phone_model_id,
        :selected_imei,
        :selected_color
      )
    end

    # Calculate max financing amount based on customer age
    # 50-60 years: L. 3,000
    # 21-49 years: L. 3,500
    def max_financing_amount_for_customer
      customer = @credit_application.customer
      return MAX_FINANCING_STANDARD unless customer&.date_of_birth.present?

      age = customer_age(customer.date_of_birth)
      return MAX_FINANCING_STANDARD unless age

      if age >= 50 && age <= 60
        MAX_FINANCING_SENIOR
      else
        MAX_FINANCING_STANDARD
      end
    end

    def customer_age(date_of_birth)
      return nil unless date_of_birth.present?

      dob = date_of_birth.is_a?(Date) ? date_of_birth : Date.parse(date_of_birth.to_s) rescue nil
      return nil unless dob

      today = Date.today
      age = today.year - dob.year
      age -= 1 if today.yday < dob.yday
      age
    end
  end
end
