# app/controllers/vendor/device_selections_controller.rb
module Vendor
  class DeviceSelectionsController < ApplicationController
    before_action :set_credit_application
    before_action :authorize_credit_application
    before_action :ensure_device_selected, only: [ :confirmation ]

    # Step 10: Catálogo Teléfonos (Device Selection)
    # GET /vendor/device_selection/:credit_application_id
    def show
      @phone_models = PhoneModel.active.order(:brand, :model)
    end

    # Step 10: Process device selection
    # PATCH /vendor/device_selection/:credit_application_id
    def update
      if @credit_application.update(device_selection_params)
        redirect_to vendor_device_selection_confirmation_path(@credit_application),
                    notice: "Teléfono seleccionado correctamente. Proceda a confirmación."
      else
        @phone_models = PhoneModel.active.order(:brand, :model)
        flash.now[:alert] = "Error al seleccionar el teléfono. Verifique los datos."
        render :show, status: :unprocessable_entity
      end
    end

    # Step 11: Confirmación (Purchase Summary)
    # GET /vendor/device_selections/:credit_application_id/confirmation
    def confirmation
      # @credit_application already loaded with selected_phone_model
    end

    private

    def set_credit_application
      @credit_application = CreditApplication.find(params[:id])
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
  end
end
