# frozen_string_literal: true

module Admin
  class PhoneModelsController < ApplicationController
    before_action :set_phone_model, only: [ :show, :edit, :update, :destroy ]
    before_action :authorize_phone_model_management

    def index
      @phone_models = policy_scope(PhoneModel).order(brand: :asc, model: :asc)

      # Filter by brand
      if params[:brand].present?
        @phone_models = @phone_models.where(brand: params[:brand])
      end

      # Filter by active status
      if params[:status].present?
        @phone_models = @phone_models.where(active: params[:status] == "active")
      end

      # Search by model name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @phone_models = @phone_models.where("model ILIKE ? OR brand ILIKE ?", search_term, search_term)
      end

      # Get unique brands for filter dropdown
      @brands = PhoneModel.distinct.pluck(:brand).sort

      # Paginate results (20 per page)
      @phone_models = @phone_models.page(params[:page]).per(20)
    end

    def show
      # Phone details page
    end

    def new
      @phone_model = PhoneModel.new(active: true)
    end

    def create
      @phone_model = PhoneModel.new(phone_model_params)

      if @phone_model.save
        redirect_to admin_phone_models_path, notice: "Teléfono creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # Edit phone form
    end

    def update
      if @phone_model.update(phone_model_params)
        redirect_to admin_phone_model_path(@phone_model), notice: "Teléfono actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @phone_model.devices.exists?
        redirect_to admin_phone_models_path, alert: "No se puede eliminar este teléfono porque tiene dispositivos asociados."
      else
        @phone_model.destroy
        redirect_to admin_phone_models_path, notice: "Teléfono #{@phone_model.brand} #{@phone_model.model} eliminado exitosamente."
      end
    end

    private

    def set_phone_model
      @phone_model = PhoneModel.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_phone_models_path, alert: "Teléfono no encontrado."
    end

    def authorize_phone_model_management
      authorize nil, policy_class: Admin::PhoneModelsPolicy
    end

    def phone_model_params
      params.require(:phone_model).permit(:brand, :model, :storage, :price, :active)
    end
  end
end
