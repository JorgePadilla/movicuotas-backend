# frozen_string_literal: true

module Vendor
  class CustomerSearchController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize nil, policy_class: Vendor::CustomerSearchPolicy

      if params[:identification_number].present?
        # Clean the identification number (remove dashes, spaces)
        @clean_id = params[:identification_number].gsub(/[-\s]/, "")

        # Validate the cleaned ID
        if @clean_id.length != 13 || @clean_id !~ /\A\d+\z/
          @step = :invalid
          @alert_color = "#f59e0b"  # Orange/Warning
          @alert_message = "Número de identidad inválido. Debe tener 13 dígitos."
          @search_query = params[:identification_number]
          return
        end

        # Find customer by identification number
        @customer = Customer.find_by(identification_number: @clean_id)

        if @customer
          # Check if customer has any active loans across ALL stores
          @active_loan = @customer.loans.active.first

          # Check if customer has an approved credit application (incomplete process)
          # If customer has no active loan but has an approved application, they can continue
          @approved_application = @customer.credit_applications.approved.order(created_at: :desc).first

          # Check if customer has a pending credit application (in progress)
          @pending_application = @customer.credit_applications.pending.order(created_at: :desc).first

          # Determine which step to show
          if @active_loan
            # Step 3a: Cliente Bloqueado
            @step = :blocked
            @alert_color = "#ef4444"  # Red
            @alert_message = "Cliente tiene crédito activo. Finaliza el pago de tus Movicuotas para aplicar a más créditos!"
          elsif @approved_application
            # Step: Solicitud Aprobada - Continuar proceso
            @step = :continue_approved
            @alert_color = "#3b82f6"  # Blue
            @alert_message = "Cliente tiene una solicitud aprobada. Continua con la seleccion de dispositivo."
          elsif @pending_application
            # Step: Solicitud Pendiente - Continuar proceso
            @step = :continue_pending
            @alert_color = "#f59e0b"  # Orange
            @alert_message = "Cliente tiene una solicitud en proceso. Continua desde donde se quedo."
          else
            # Step 3b: Cliente Disponible
            @step = :available
            @alert_color = "#10b981"  # Green
            @alert_message = "Cliente disponible para nuevo crédito"
          end
        else
          # Customer not found - can start new application
          @step = :not_found
          @alert_color = "#10b981"  # Green/Success (can start new application)
          @alert_message = "Cliente no registrado en el sistema. Puedes crear un nuevo registro e iniciar una solicitud de crédito."
        end

        # Set the search query for display
        @search_query = params[:identification_number]
      else
        # Initial page load - no search yet
        @step = :initial
      end
    end

    private

    def pundit_policy_class
      Vendor::CustomerSearchPolicy
    end
  end
end
