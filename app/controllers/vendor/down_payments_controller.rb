# frozen_string_literal: true

module Vendor
  class DownPaymentsController < ApplicationController
    before_action :set_contract
    before_action :set_loan

    # GET /vendor/contracts/:contract_id/down_payment
    # Step 14.5: Down payment collection (between signature and success)
    def show
      authorize @loan, :collect_down_payment?

      # If down payment already collected, redirect to success
      if @loan.down_payment_collected?
        redirect_to success_vendor_contract_path(@contract),
                    notice: "La prima ya fue registrada."
        nil
      end
    end

    # PATCH /vendor/contracts/:contract_id/down_payment
    def update
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
      redirect_to success_vendor_contract_path(@contract),
                  notice: "Prima en efectivo registrada exitosamente."
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

      redirect_to success_vendor_contract_path(@contract),
                  notice: "Comprobante de depósito registrado. Pendiente de verificación por administración."
    end
  end
end
