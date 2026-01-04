# frozen_string_literal: true

module Admin
  class ContractsController < ApplicationController
    before_action :set_contract, only: [ :show, :edit, :update_qr_code, :download_qr_code ]
    after_action :verify_authorized, except: [ :index ]

    # Admin contracts index with filtering and search
    def index
      @contracts = policy_scope(Contract)
      @contracts = @contracts.joins(:loan).where("loans.contract_number ILIKE ?", "%#{params[:search]}%") if params[:search].present?
      @contracts = @contracts.order(created_at: :desc).page(params[:page]).per(25)
    end

    # View contract details and upload QR code
    def show
      authorize @contract
    end

    # Edit contract and QR code
    def edit
      authorize @contract
    end

    # Update QR code for contract
    def update_qr_code
      authorize @contract

      if params[:contract][:qr_code].present?
        begin
          qr_code_file = params[:contract][:qr_code]
          @contract.upload_qr_code!(qr_code_file, current_user)

          redirect_to admin_contract_path(@contract),
                      notice: "Código QR cargado exitosamente."
        rescue StandardError => e
          Rails.logger.error "QR code upload failed: #{e.message}"
          flash.now[:alert] = "Error al cargar el código QR: #{e.message}"
          render :edit, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = "Por favor, selecciona un archivo QR."
        render :edit, status: :unprocessable_entity
      end
    end

    # Download QR code
    def download_qr_code
      authorize @contract

      if @contract.qr_code_present?
        send_data @contract.qr_code.download,
                  filename: @contract.qr_code.filename.to_s,
                  type: @contract.qr_code.content_type,
                  disposition: "attachment"
      else
        redirect_to admin_contract_path(@contract),
                    alert: "No hay código QR disponible para descargar."
      end
    end

    private

    def set_contract
      @contract = Contract.find(params[:id])
      @loan = @contract.loan
      @customer = @loan&.customer
    end
  end
end
