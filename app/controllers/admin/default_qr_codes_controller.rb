# frozen_string_literal: true

module Admin
  class DefaultQrCodesController < ApplicationController
    before_action :set_default_qr_code
    after_action :verify_authorized, except: [:index]

    # Admin default QR code management
    def index
      authorize @default_qr_code
    end

    # Edit default QR code
    def edit
      authorize @default_qr_code
    end

    # Update default QR code
    def update
      authorize @default_qr_code

      if params[:default_qr_code][:qr_code].present?
        begin
          qr_code_file = params[:default_qr_code][:qr_code]
          @default_qr_code.upload_qr_code!(qr_code_file, current_user)

          redirect_to admin_default_qr_codes_path,
                      notice: 'Código QR por defecto cargado exitosamente.'
        rescue StandardError => e
          Rails.logger.error "QR code upload failed: #{e.message}"
          flash.now[:alert] = "Error al cargar el código QR: #{e.message}"
          render :edit, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = 'Por favor, selecciona un archivo QR.'
        render :edit, status: :unprocessable_entity
      end
    end

    # Download default QR code
    def download
      authorize @default_qr_code

      if @default_qr_code.qr_code_present?
        send_data @default_qr_code.qr_code.download,
                  filename: @default_qr_code.qr_code.filename.to_s,
                  type: @default_qr_code.qr_code.content_type,
                  disposition: 'attachment'
      else
        redirect_to admin_default_qr_codes_path,
                    alert: 'No hay código QR disponible para descargar.'
      end
    end

    private

    def set_default_qr_code
      @default_qr_code = DefaultQrCode.default
    end
  end
end
