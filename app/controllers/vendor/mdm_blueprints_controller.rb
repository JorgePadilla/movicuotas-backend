# frozen_string_literal: true

module Vendor
  class MdmBlueprintsController < ApplicationController
    # Step 16: QR Code display for MDM configuration
    before_action :set_mdm_blueprint
    before_action :authorize_mdm_blueprint
    before_action :ensure_qr_code_generated

    def show
      # @mdm_blueprint already set
      @device = @mdm_blueprint.device
      @loan = @device.loan
      @customer = @loan.customer
    end

    private

    def set_mdm_blueprint
      @mdm_blueprint = MdmBlueprint.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to vendor_customer_search_path,
                  alert: "Configuración MDM no encontrada."
    end

    def authorize_mdm_blueprint
      authorize @mdm_blueprint
    end

    def ensure_qr_code_generated
      # Generate QR code if not already attached
      unless @mdm_blueprint.qr_code_image.attached?
        @mdm_blueprint.generate_qr_code_image
        # Reload to get the attached image
        @mdm_blueprint.reload
      end
    end
  end
end
