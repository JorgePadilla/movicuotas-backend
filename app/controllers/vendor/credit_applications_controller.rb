# frozen_string_literal: true

module Vendor
  class CreditApplicationsController < ApplicationController
    before_action :set_credit_application, only: [
      :edit, :update, :photos, :update_photos, :employment, :update_employment,
      :summary, :submit, :approved, :rejected, :show,
      :verify_otp, :send_otp, :submit_otp_verification, :resend_otp
    ]
    before_action :authorize_credit_application, only: [
      :edit, :update, :photos, :update_photos, :employment, :update_employment,
      :summary, :submit, :approved, :rejected, :show,
      :verify_otp, :send_otp, :submit_otp_verification, :resend_otp
    ]

    # Step 4: Datos Generales
    def new
      # Customer ID comes from Step 3b (Cliente Disponible)
      @customer = find_or_initialize_customer

      # Don't pre-fill date_of_birth - let JavaScript handle default (July 1, 2000)
      # Leave it nil so the input field is clean

      @credit_application = CreditApplication.new(customer: @customer)
      authorize @credit_application
    end

    # Step 4 submission: Create customer and credit application
    def create
      Rails.logger.info "Credit application create params: #{params.inspect}"
      Rails.logger.info "Credit application params (permitted): #{credit_application_params.inspect}"

      # Build credit application with nested customer attributes
      @credit_application = CreditApplication.new(credit_application_params)
      @credit_application.vendor = current_user
      @credit_application.status = :pending

      # Get customer from the built association for error display
      @customer = @credit_application.customer || find_or_initialize_customer
      Rails.logger.info "Customer attributes: #{@customer.attributes.inspect}"
      Rails.logger.info "Credit application attributes: #{@credit_application.attributes.inspect}"

      authorize @credit_application

      # Use transaction for atomic save
      saved = false
      Rails.logger.info "Attempting to save credit application and customer..."
      ActiveRecord::Base.transaction do
        if @credit_application.save
          saved = true
          Rails.logger.info "Credit application saved successfully with ID: #{@credit_application.id}"
          Rails.logger.info "Customer saved with ID: #{@customer.id}"
        else
          # Rollback the transaction if save fails
          Rails.logger.error "Credit application save failed. Errors: #{@credit_application.errors.full_messages}"
          Rails.logger.error "Customer errors: #{@customer.errors.full_messages}" if @customer.errors.any?
          raise ActiveRecord::Rollback
        end
      end

      if saved
        Rails.logger.info "Redirecting to photos path: #{photos_vendor_credit_application_path(@credit_application)}"
        redirect_to photos_vendor_credit_application_path(@credit_application),
                    notice: "Datos generales guardados. Sube las fotografías de identificación."
      else
        # Log errors for debugging
        Rails.logger.error "Final credit application errors: #{@credit_application.errors.full_messages}" if @credit_application.errors.any?
        Rails.logger.error "Final customer errors: #{@customer.errors.full_messages}" if @customer.errors.any?

        render :new, status: :unprocessable_entity
      end
    end

    # Step 1: Edit Datos Generales (for going back to previous step)
    def edit
      @customer = @credit_application.customer
    end

    # Update Datos Generales
    def update
      if @credit_application.update(credit_application_params)
        redirect_to photos_vendor_credit_application_path(@credit_application),
                    notice: "Datos generales actualizados."
      else
        @customer = @credit_application.customer
        render :edit, status: :unprocessable_entity
      end
    end

    # Step 5: Fotografías
    def photos
      # Rendered by view
    end

    # Step 5 submission: Upload photos
    def update_photos
      Rails.logger.info "Updating photos for credit application #{@credit_application.id}"

      # Check if photos params are present (new photos being uploaded)
      if params[:credit_application].present?
        Rails.logger.info "Photos params: #{photos_params.inspect}"

        if @credit_application.update(photos_params)
          Rails.logger.info "Photos updated successfully for credit application #{@credit_application.id}"
          redirect_to verify_otp_vendor_credit_application_path(@credit_application),
                      notice: "Fotografias guardadas. Selecciona el metodo de verificacion."
        else
          Rails.logger.error "Failed to update photos for credit application #{@credit_application.id}"
          Rails.logger.error "Errors: #{@credit_application.errors.full_messages.inspect}"
          flash.now[:alert] = "Error: #{@credit_application.errors.full_messages.join(', ')}"
          render :photos, status: :unprocessable_entity
        end
      else
        # No new photos uploaded - check if photos are already attached
        if photos_already_attached?
          Rails.logger.info "No new photos, but existing photos found. Proceeding to verification."
          redirect_to verify_otp_vendor_credit_application_path(@credit_application),
                      notice: "Continuando con las fotografias existentes."
        else
          Rails.logger.error "No photos attached and no new photos uploaded"
          flash.now[:alert] = "Debes capturar las 3 fotografias requeridas."
          render :photos, status: :unprocessable_entity
        end
      end
    end

    # Step 6: Datos Laborales
    def employment
      # Rendered by view
    end

    # Step 6 submission: Save employment data
    def update_employment
      Rails.logger.info "Updating employment data for credit application #{@credit_application.id}"
      Rails.logger.info "Params: #{employment_params.inspect}"

      # Set validation context for employment data step
      @credit_application.updating_employment = true

      if @credit_application.update(employment_params)
        Rails.logger.info "Employment data saved successfully"
        redirect_to summary_vendor_credit_application_path(@credit_application),
                    notice: "Datos laborales guardados. Revisa el resumen."
      else
        Rails.logger.error "Failed to update employment data. Errors: #{@credit_application.errors.full_messages}"
        Rails.logger.error "Employment status: #{@credit_application.employment_status.inspect}"
        Rails.logger.error "Salary range: #{@credit_application.salary_range.inspect}"
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

    # Step 5.5: OTP Verification page
    def verify_otp
      # Ensure all 3 photos are uploaded before proceeding
      unless photos_already_attached?
        redirect_to photos_vendor_credit_application_path(@credit_application),
                    alert: "Debe capturar las 3 fotografías requeridas (frente de identidad, reverso de identidad y verificación facial) antes de continuar."
        return
      end

      # Check if already verified - allow proceeding
      if @credit_application.otp_verified? && !@credit_application.otp_expired?
        redirect_to employment_vendor_credit_application_path(@credit_application),
                    notice: "Verificacion ya completada."
        return
      end
      # Render verify_otp view - shows method selection if OTP not sent, code entry if sent
    end

    # Send OTP after method selection
    def send_otp
      verification_method = params[:verification_method]

      unless %w[sms email].include?(verification_method)
        flash[:alert] = "Por favor selecciona un metodo de verificacion."
        redirect_to verify_otp_vendor_credit_application_path(@credit_application)
        return
      end

      # Save the selected verification method
      @credit_application.update!(verification_method: verification_method)

      # Send OTP
      service = OtpVerificationService.new(@credit_application)
      result = service.send_otp

      if result[:success]
        redirect_to verify_otp_vendor_credit_application_path(@credit_application),
                    notice: result[:message]
      else
        flash[:alert] = result[:errors].join(", ")
        redirect_to verify_otp_vendor_credit_application_path(@credit_application)
      end
    end

    # Step 5.5 submission: Validate OTP code
    def submit_otp_verification
      submitted_code = params[:otp_code]&.strip

      if submitted_code.blank?
        flash.now[:alert] = "Por favor ingresa el codigo de verificacion."
        render :verify_otp, status: :unprocessable_entity
        return
      end

      service = OtpVerificationService.new(@credit_application)
      result = service.verify(submitted_code)

      if result[:success]
        redirect_to employment_vendor_credit_application_path(@credit_application),
                    notice: "Verificacion exitosa. Completa los datos laborales."
      else
        flash.now[:alert] = result[:errors].join(", ")
        render :verify_otp, status: :unprocessable_entity
      end
    end

    # Resend OTP code
    def resend_otp
      service = OtpVerificationService.new(@credit_application)
      result = service.send_otp

      respond_to do |format|
        if result[:success]
          format.html { redirect_to verify_otp_vendor_credit_application_path(@credit_application), notice: result[:message] }
          format.turbo_stream {
            flash.now[:notice] = result[:message]
            render turbo_stream: turbo_stream.replace("otp-form", partial: "otp_form", locals: { credit_application: @credit_application })
          }
        else
          format.html { redirect_to verify_otp_vendor_credit_application_path(@credit_application), alert: result[:errors].join(", ") }
          format.turbo_stream {
            flash.now[:alert] = result[:errors].join(", ")
            render turbo_stream: turbo_stream.replace("otp-form", partial: "otp_form", locals: { credit_application: @credit_application })
          }
        end
      end
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
      elsif params[:identification_number].present?
        # Find existing customer by identification_number or initialize new (from search)
        Customer.find_or_initialize_by(identification_number: params[:identification_number])
      elsif credit_application_params[:customer_attributes].present? &&
            credit_application_params[:customer_attributes][:identification_number].present?
        # Find existing customer by identification_number or initialize new (from form submission)
        identification = credit_application_params[:customer_attributes][:identification_number]
        Customer.find_or_initialize_by(identification_number: identification)
      else
        Customer.new
      end
    end


    def credit_application_params
      params.require(:credit_application).permit(
        :notes,
        :selected_phone_model_id,
        :selected_imei,
        :selected_color,
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
          :email
          # status is not included - uses default "active" from enum
        ]
      )
    end

    def photos_params
      params.require(:credit_application).permit(
        :id_front_image, :id_back_image, :facial_verification_image
      )
    end

    def employment_params
      params.require(:credit_application).permit(
        :employment_status, :salary_range
      )
    end

    def photos_already_attached?
      @credit_application.id_front_image.attached? &&
        @credit_application.id_back_image.attached? &&
        @credit_application.facial_verification_image.attached?
    end
  end
end
