# frozen_string_literal: true

module Vendor
  class MdmChecklistsController < ApplicationController
    # Step 17: Device Configuration Checklist
    # This controller handles the final verification that MDM configuration is complete
    # before returning the device to the customer.
    #
    # Flow:
    # 1. Display checklist with three verification items:
    #    - BluePrint scanned and configuration completed
    #    - MDM app installed and confirmed
    #    - MoviCuotas app installed and logged in
    # 2. User marks items as complete
    # 3. User submits checklist to finalize the sale and return to Step 2

    before_action :set_mdm_blueprint
    before_action :authorize_mdm_blueprint

    def show
      # Display the device configuration checklist
      @device = @mdm_blueprint.device
      @loan = @device.loan
      @customer = @loan.customer
    end

    def create
      # Submit the checklist verification
      @device = @mdm_blueprint.device
      @loan = @device.loan
      @customer = @loan.customer

      # Validate that all required checklist items are checked
      unless checklist_params[:blueprint_scanned] == "1" &&
             checklist_params[:mdm_installed] == "1" &&
             checklist_params[:movicuotas_installed] == "1"
        flash.now[:alert] = "Por favor marca todos los elementos del checklist antes de continuar."
        return render :show, status: :unprocessable_entity
      end

      # Mark device configuration as complete
      if @device.update(lock_status: "locked")
        # Clear any session data related to this sale
        clear_session_data

        # Redirect back to customer search (Step 2 - main screen)
        redirect_to vendor_customer_search_path,
                    notice: "¡Felicidades! El proceso de venta ha sido completado. El dispositivo está configurado y listo para usar."
      else
        flash.now[:alert] = "Error al completar el proceso. Por favor intenta nuevamente."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_mdm_blueprint
      @mdm_blueprint = MdmBlueprint.find(params[:mdm_blueprint_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to vendor_customer_search_path,
                  alert: "Configuración MDM no encontrada."
    end

    def authorize_mdm_blueprint
      authorize @mdm_blueprint, :show?
    end

    def checklist_params
      params.require(:mdm_checklist).permit(
        :blueprint_scanned,
        :mdm_installed,
        :movicuotas_installed
      )
    end

    def clear_session_data
      session.delete(:credit_application_id)
      session.delete(:device_id)
      session.delete(:contract_id)
      session.delete(:loan_attributes)
      session.delete(:mdm_blueprint_id)
    end
  end
end
