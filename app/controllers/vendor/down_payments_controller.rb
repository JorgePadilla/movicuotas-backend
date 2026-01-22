# frozen_string_literal: true

module Vendor
  class DownPaymentsController < ApplicationController
    before_action :set_contract
    before_action :set_loan

    # GET /vendor/contracts/:contract_id/down_payment
    # Step 15: Down payment collection (between signature and QR MDM)
    def show
      # Check if contract is signed before authorizing
      unless @contract.signed?
        redirect_to signature_vendor_contract_path(@contract),
                    alert: "El contrato debe estar firmado antes de recolectar la prima."
        return
      end

      # If down payment already collected, redirect to QR MDM (step 16)
      if @loan.down_payment_collected?
        @device = @loan.device
        if @device&.mdm_blueprint.present?
          redirect_to vendor_mdm_blueprint_path(@device.mdm_blueprint),
                      notice: "La prima ya fue registrada."
        else
          redirect_to success_vendor_contract_path(@contract),
                      notice: "La prima ya fue registrada."
        end
        return
      end

      authorize @loan, :collect_down_payment?
    end

    # PATCH /vendor/contracts/:contract_id/down_payment
    def update
      # Check if contract is signed
      unless @contract.signed?
        redirect_to signature_vendor_contract_path(@contract),
                    alert: "El contrato debe estar firmado antes de recolectar la prima."
        return
      end

      authorize @loan, :collect_down_payment?

      payment_method = params[:down_payment_method]

      if payment_method == "cash"
        handle_cash_payment
      elsif payment_method == "deposit"
        handle_deposit_payment
      else
        flash.now[:alert] = "Debe seleccionar un método de pago."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_contract
      @contract = Contract.find(params[:contract_id])
    end

    def set_loan
      @loan = @contract.loan
      @customer = @loan.customer
    end

    def handle_cash_payment
      unless params[:cash_confirmed] == "1"
        flash.now[:alert] = "Debe confirmar la recepción de la prima en efectivo."
        render :show, status: :unprocessable_entity
        return
      end

      @loan.confirm_cash_down_payment!(current_user)
      redirect_to_next_step("Prima en efectivo registrada exitosamente.")
    end

    def handle_deposit_payment
      receipt = params[:down_payment_receipt]

      if receipt.blank?
        flash.now[:alert] = "Debe subir el comprobante de depósito."
        render :show, status: :unprocessable_entity
        return
      end

      # Attach the receipt image
      @loan.down_payment_receipt.attach(receipt)
      @loan.submit_deposit_down_payment!(current_user)

      redirect_to_next_step("Comprobante de depósito registrado. Pendiente de verificación por administración.")
    end

    def redirect_to_next_step(message)
      device = @loan.device
      if device&.mdm_blueprint.present?
        redirect_to vendor_mdm_blueprint_path(device.mdm_blueprint), notice: message
      else
        redirect_to success_vendor_contract_path(@contract), notice: message
      end
    end
  end
end
