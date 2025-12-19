# frozen_string_literal: true

module Vendor
  class PaymentCalculatorsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: [ :new, :calculate ]

    # Step 12: Payment Calculator
    # Display calculator form with down payment options and installment terms
    def new
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      # Get parameters from previous step (Step 11: Confirmation)
      # Phone price and approved amount should be passed via session or params
      @phone_price = params[:phone_price]&.to_f || session[:phone_price] || 0
      @approved_amount = params[:approved_amount]&.to_f || session[:approved_amount] || 0
      @credit_application_id = params[:credit_application_id] || session[:credit_application_id]

      # Validate phone price against approved amount
      if @phone_price > 0 && @approved_amount > 0 && @phone_price > @approved_amount
        flash[:alert] = "El precio del teléfono (L. #{@phone_price}) excede el monto aprobado (L. #{@approved_amount})"
        redirect_to vendor_customer_search_path and return
      end

      # Get customer date of birth for age validation
      @date_of_birth = fetch_date_of_birth
      unless @date_of_birth
        flash[:alert] = "No se pudo obtener la fecha de nacimiento del cliente. Verifique la solicitud de crédito."
        redirect_to vendor_customer_search_path and return
      end

      # Default calculator values
      @down_payment_percentage = params[:down_payment_percentage]&.to_i || 30
      @number_of_installments = params[:number_of_installments]&.to_i || 6

      # Calculate initial installment amount
      @calculator = BiweeklyCalculatorService.new(
        phone_price: @phone_price,
        down_payment_percentage: @down_payment_percentage,
        number_of_installments: @number_of_installments,
        date_of_birth: @date_of_birth
      )

      @result = @calculator.calculate
    end

    # Calculate installment amount dynamically (Turbo Stream)
    # Called via AJAX/Turbo when user changes down payment or installment term
    def calculate
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      phone_price = params[:phone_price]&.to_f || 0
      down_payment_percentage = params[:down_payment_percentage]&.to_i || 30
      number_of_installments = params[:number_of_installments]&.to_i || 6
      date_of_birth = params[:date_of_birth].present? ? params[:date_of_birth] : fetch_date_of_birth

      unless date_of_birth
        return respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "calculator_errors",
              partial: "vendor/payment_calculators/errors",
              locals: { errors: [ "No se pudo obtener la fecha de nacimiento del cliente" ] }
            )
          end
          format.html do
            flash.now[:alert] = "No se pudo obtener la fecha de nacimiento del cliente"
            render :new
          end
        end
      end

      calculator = BiweeklyCalculatorService.new(
        phone_price: phone_price,
        down_payment_percentage: down_payment_percentage,
        number_of_installments: number_of_installments,
        date_of_birth: date_of_birth
      )

      result = calculator.calculate

      respond_to do |format|
        format.turbo_stream do
          if result[:success]
            render turbo_stream: turbo_stream.replace(
              "calculator_results",
              partial: "vendor/payment_calculators/results",
              locals: { result: result }
            )
          else
            render turbo_stream: turbo_stream.replace(
              "calculator_errors",
              partial: "vendor/payment_calculators/errors",
              locals: { errors: result[:errors] }
            )
          end
        end

        format.html do
          if result[:success]
            flash.now[:notice] = "Cálculo actualizado"
          else
            flash.now[:alert] = result[:errors].join(", ")
          end
          render :new
        end
      end
    end

    # Create loan with calculated installments (proceed to Step 13: Contract)
    def create
      authorize nil, policy_class: Vendor::PaymentCalculatorPolicy

      # This action will be implemented in Phase 2: Loan Finalization
      # For now, redirect to contract step with calculated parameters
      flash[:notice] = "Calculadora completada. Procediendo a contrato..."
      redirect_to vendor_contracts_path # Placeholder - will be implemented in phase2-vendor-contract-signature
    end

    private

    # Fetch customer date of birth from credit application
    def fetch_date_of_birth
      # Try to get from params first
      return params[:date_of_birth] if params[:date_of_birth].present?

      # Try to get from session
      return session[:date_of_birth] if session[:date_of_birth].present?

      # Try to get from credit application
      if @credit_application_id.present?
        credit_application = CreditApplication.find_by(id: @credit_application_id)
        return credit_application.customer.date_of_birth if credit_application&.customer
      end

      # Try to get from customer in session
      if session[:customer_id].present?
        customer = Customer.find_by(id: session[:customer_id])
        return customer.date_of_birth if customer
      end

      nil
    end
  end
end
