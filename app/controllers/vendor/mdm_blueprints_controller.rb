# frozen_string_literal: true

module Vendor
  class MdmBlueprintsController < ApplicationController
    # Placeholder for Step 16: QR Code display
    # This will be implemented in the phase2-vendor-mdm-configuration branch

    def show
      @mdm_blueprint = MdmBlueprint.find(params[:id])
      authorize @mdm_blueprint

      # For now, redirect to loan success page with a message
      redirect_to vendor_loan_path(@mdm_blueprint.device.loan),
                  notice: "Esta funcionalidad será implementada en la fase de configuración MDM."
    end
  end
end