# frozen_string_literal: true

module Vendor
  class ContractsController < ApplicationController
    before_action :set_contract, except: [:new, :create]
    after_action :verify_authorized, except: [:signature, :save_signature]
    after_action :verify_policy_scoped, only: :index

    # Step 13: Display contract for review
    def show
      authorize @contract
      @service = ContractGeneratorService.new(@contract)
      @contract_html = @service.generate_html
      @installment_details = @service.installment_details
    end

    # Step 14: Digital signature capture
    def signature
      # Skip authorization for signature page - contract already authorized via show
      # but we still need to ensure user can view the contract
      authorize @contract if @contract.present?
    end

    # Save signature image
    def save_signature
      authorize @contract

      if params[:signature_data].present?
        # Decode base64 signature data
        signature_data = params[:signature_data]
        signature_data = signature_data.split(',').last if signature_data.include?(',')
        decoded_signature = Base64.decode64(signature_data)

        # Create a temporary file
        temp_file = Tempfile.new(['signature', '.png'], encoding: 'ascii-8bit')
        temp_file.write(decoded_signature)
        temp_file.rewind

        # Attach to contract
        if @contract.sign!(temp_file, @contract.loan.customer.full_name, current_user)
          # Update loan status if needed (loan should already be active)
          @contract.loan.update(status: 'active') if @contract.loan.draft?

          # Create notification for customer
          Notification.create!(
            customer: @contract.loan.customer,
            title: 'Contrato Firmado',
            body: "Tu contrato de crédito #{@contract.loan.contract_number} ha sido firmado exitosamente. Tu crédito está ahora activo.",
            notification_type: 'contract_signed',
            sent_at: Time.current
          )

          redirect_to success_vendor_contract_path(@contract),
                      notice: 'Firma guardada exitosamente. ¡Crédito aplicado!'
        else
          flash.now[:alert] = 'Error al guardar la firma. Intente nuevamente.'
          render :signature, status: :unprocessable_entity
        end

        temp_file.close
        temp_file.unlink
      else
        flash.now[:alert] = 'No se detectó firma. Por favor, firme en el área designada.'
        render :signature, status: :unprocessable_entity
      end
    end

    # Download contract as PDF (optional feature)
    def download
      authorize @contract

      begin
        service = ContractGeneratorService.new(@contract)
        pdf_data = service.generate_pdf

        filename = "contrato-#{@loan.contract_number}.pdf"

        send_data pdf_data,
                  filename: filename,
                  type: 'application/pdf',
                  disposition: 'attachment'
      rescue StandardError => e
        Rails.logger.error "PDF generation failed: #{e.message}"
        flash[:alert] = 'Error al generar el PDF. Por favor, intente nuevamente.'
        redirect_to vendor_contract_path(@contract)
      end
    end

    # Step 15: Success confirmation after signature
    def success
      authorize @contract
      @loan = @contract.loan
      @customer = @loan.customer
      @device = @loan.device
    end

    private

    def set_contract
      # Find contract by loan_id parameter (passed from previous step)
      if params[:loan_id].present?
        @loan = Loan.find(params[:loan_id])
        @contract = @loan.contract || create_contract_for_loan(@loan)
      elsif params[:id].present?
        @contract = Contract.find(params[:id])
        @loan = @contract.loan
      else
        redirect_to vendor_customer_search_path,
                    alert: 'No se especificó préstamo o contrato.'
      end
    end

    def create_contract_for_loan(loan)
      # Create contract if it doesn't exist
      contract = Contract.new(loan: loan)
      authorize contract, :create?

      if contract.save
        contract
      else
        redirect_to vendor_customer_search_path,
                    alert: "Error al crear contrato: #{contract.errors.full_messages.join(', ')}"
      end
    end

    # Strong parameters (if needed for updates)
    def contract_params
      params.require(:contract).permit(:notes)
    end
  end
end