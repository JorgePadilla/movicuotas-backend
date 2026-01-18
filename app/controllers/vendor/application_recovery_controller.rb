# frozen_string_literal: true

module Vendor
  class ApplicationRecoveryController < ApplicationController
    # Step 9: Recuperar Solicitud
    # Show form to enter approved application number
    def show
      @application_number = params[:application_number]
      @credit_application = find_approved_application if @application_number.present?
      if @credit_application.present?
        authorize @credit_application
      else
        skip_authorization
        skip_policy_scope
      end
    end

    # Process application number submission
    def create
      @application_number = params[:application_number]
      @credit_application = find_approved_application

      if @credit_application.present?
        authorize @credit_application
        render :show
      else
        skip_authorization
        skip_policy_scope
        flash.now[:alert] = "No se encontró una solicitud aprobada con el número #{@application_number}. Verifica el número e intenta nuevamente."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def find_approved_application
      return nil if @application_number.blank?

      CreditApplication.approved
                       .includes(:customer)
                       .find_by(application_number: @application_number)
    end
  end
end
