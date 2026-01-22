# frozen_string_literal: true

module Vendor
  class MdmChecklistsController < ApplicationController
    # Step 17: Device Configuration Checklist
    # This controller handles the final verification before returning the device.
    #
    # Flow:
    # 1. Display checklist with verification:
    #    - MoviCuotas app activated with activation code
    # 2. User marks item as complete
    # 3. User submits checklist to finalize the sale and go to Thank You page (Step 18)

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

      # Validate that the checklist item is checked
      unless checklist_params[:movicuotas_installed] == "1"
        flash.now[:alert] = "Por favor confirma que la app MOVICUOTAS está activada antes de continuar."
        return render :show, status: :unprocessable_entity
      end

      # Mark device configuration as complete
      if @device.update(lock_status: "locked")
        # Clear any session data related to this sale
        clear_session_data

        # Redirect to success/thank you page (Step 18)
        redirect_to success_vendor_contract_path(@loan.contract),
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
      params.require(:mdm_checklist).permit(:movicuotas_installed)
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
