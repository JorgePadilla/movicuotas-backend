# frozen_string_literal: true

module Vendor
  class CreditApplicationsController < ApplicationController
    before_action :set_credit_application, only: [
      :photos, :update_photos, :employment, :update_employment,
      :summary, :submit, :approved, :rejected, :show
    ]
    before_action :authorize_credit_application, only: [
      :photos, :update_photos, :employment, :update_employment,
      :summary, :submit, :approved, :rejected, :show
    ]

    # Step 4: Datos Generales
    def new
      # Customer ID comes from Step 3b (Cliente Disponible)
      @customer = find_or_initialize_customer
      @credit_application = CreditApplication.new(customer: @customer)
      authorize @credit_application
    end

    # Step 4 submission: Create customer and credit application
    def create
      @customer = find_or_initialize_customer
      @credit_application = CreditApplication.new(credit_application_params)
      @credit_application.customer = @customer
      @credit_application.vendor = current_user
      @credit_application.status = :pending

      authorize @credit_application

      if @customer.save && @credit_application.save
        redirect_to photos_vendor_credit_application_path(@credit_application),
                    notice: "Datos generales guardados. Sube las fotografías de identificación."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # Step 5: Fotografías
    def photos
      # Rendered by view
    end

    # Step 5 submission: Upload photos
    def update_photos
      if @credit_application.update(photos_params)
        redirect_to employment_vendor_credit_application_path(@credit_application),
                    notice: "Fotografías subidas. Completa los datos laborales."
      else
        render :photos, status: :unprocessable_entity
      end
    end

    # Step 6: Datos Laborales
    def employment
      # Rendered by view
    end

    # Step 6 submission: Save employment data
    def update_employment
      if @credit_application.update(employment_params)
        redirect_to summary_vendor_credit_application_path(@credit_application),
                    notice: "Datos laborales guardados. Revisa el resumen."
      else
        render :employment, status: :unprocessable_entity
      end
    end

    # Step 7: Resumen Solicitud
    def summary
      # Rendered by view
    end

    # Step 7 submission: Submit for approval
    def submit
      # Use CreditApprovalService to evaluate and approve/reject
      # This will be implemented later with the service
      # For now, auto-approve with a placeholder amount
      service = CreditApprovalService.new(@credit_application)
      result = service.evaluate_and_approve

      if result[:approved]
        redirect_to approved_vendor_credit_application_path(@credit_application)
      else
        redirect_to rejected_vendor_credit_application_path(@credit_application),
                    alert: result[:reason]
      end
    end

    # Step 8b: Aprobado (sin monto)
    def approved
      # Only show approval, NOT the approved_amount
      # approved_amount is stored in the model but not displayed
    end

    # Step 8a: No Aprobado
    def rejected
      # Show rejection reason
    end

    # Show application details
    def show
    end

    private

    def set_credit_application
      @credit_application = CreditApplication.find(params[:id])
    end

    def authorize_credit_application
      authorize @credit_application
    end

    def find_or_initialize_customer
      if params[:customer_id].present?
        Customer.find_by(id: params[:customer_id])
      elsif credit_application_params[:customer_attributes].present? &&
            credit_application_params[:customer_attributes][:identification_number].present?
        # Find existing customer by identification_number or initialize new
        identification = credit_application_params[:customer_attributes][:identification_number]
        Customer.find_or_initialize_by(identification_number: identification)
      else
        Customer.new
      end
    end

    def credit_application_params
      params.require(:credit_application).permit(
        :notes,
        customer_attributes: [
          :id,
          :identification_number,
          :full_name,
          :gender,
          :date_of_birth,
          :address,
          :city,
          :department,
          :phone,
          :email,
          :status
        ]
      )
    end

    def photos_params
      params.require(:credit_application).permit(
        :id_front_image, :id_back_image, :facial_verification_image,
        :verification_method
      )
    end

    def employment_params
      params.require(:credit_application).permit(
        :employment_status, :salary_range
      )
    end
  end
end
