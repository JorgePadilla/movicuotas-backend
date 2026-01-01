# frozen_string_literal: true

module Admin
  class CustomersController < ApplicationController
    before_action :set_customer, only: [:show, :edit, :update]

    def index
      @customers = policy_scope(Customer).order(created_at: :desc)

      # Filter by status if provided
      @customers = @customers.where(status: params[:status]) if params[:status].present?

      # Search by identification number or name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @customers = @customers.where("identification_number ILIKE ? OR full_name ILIKE ?", search_term, search_term)
      end

      # Paginate results (20 per page)
      @customers = @customers.page(params[:page]).per(20)
    end

    def show
      authorize @customer
    end

    def edit
      authorize @customer
    end

    def update
      authorize @customer

      if @customer.update(customer_params)
        redirect_to admin_customer_path(@customer), notice: "Cliente actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = Customer.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_customers_path, alert: "Cliente no encontrado."
    end

    def customer_params
      params.require(:customer).permit(:full_name, :email, :phone, :status)
    end
  end
end
