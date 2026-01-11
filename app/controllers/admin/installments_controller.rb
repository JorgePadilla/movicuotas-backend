# frozen_string_literal: true

module Admin
  class InstallmentsController < ApplicationController
    before_action :set_installment

    # Available bank sources for payments
    BANK_SOURCES = [
      "BAC Honduras",
      "Banpais",
      "Banco Atlántida",
      "Banco Ficohsa",
      "Banco de Occidente",
      "Banco Promerica",
      "Tigo Money",
      "Efectivo en Tienda",
      "Otro"
    ].freeze

    # POST /admin/installments/:id/mark_paid
    # Mark an installment as paid by creating a verified payment
    def mark_paid
      authorize @installment

      ActiveRecord::Base.transaction do
        # Create a verified payment for this installment
        payment = Payment.new(
          loan: @installment.loan,
          amount: payment_amount,
          payment_date: payment_date,
          payment_method: params[:payment_method] || "transfer",
          verification_status: "verified",
          verified_by: current_user,
          verified_at: Time.current,
          reference_number: params[:reference_number],
          bank_source: params[:bank_source],
          notes: params[:notes]
        )

        # Attach verification image if provided
        if params[:verification_image].present?
          payment.verification_image.attach(params[:verification_image])
        end

        payment.save!

        # Allocate payment to this installment
        payment.payment_installments.create!(
          installment: @installment,
          amount: payment_amount
        )

        # Update installment paid amount (this also updates status)
        @installment.update_paid_amount

        # Create audit log
        AuditLog.log(
          current_user,
          "installment_marked_paid",
          @installment,
          {
            installment_number: @installment.installment_number,
            loan_id: @installment.loan_id,
            payment_id: payment.id,
            amount: payment_amount,
            reference_number: params[:reference_number],
            bank_source: params[:bank_source]
          }
        )
      end

      redirect_back fallback_location: vendor_loan_path(@installment.loan),
                    notice: "Cuota ##{@installment.installment_number} marcada como pagada."
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: vendor_loan_path(@installment.loan),
                    alert: "Error al marcar cuota como pagada: #{e.message}"
    rescue StandardError => e
      Rails.logger.error("[InstallmentsController] mark_paid error: #{e.message}")
      redirect_back fallback_location: vendor_loan_path(@installment.loan),
                    alert: "Error inesperado: #{e.message}"
    end

    private

    def set_installment
      @installment = Installment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_dashboard_path, alert: "Cuota no encontrada."
    end

    def payment_amount
      # Use provided amount or default to installment remaining amount
      if params[:amount].present?
        params[:amount].to_d
      else
        @installment.remaining_amount
      end
    end

    def payment_date
      # Use provided date or default to today
      if params[:payment_date].present?
        Date.parse(params[:payment_date])
      else
        Date.current
      end
    end
  end
end
