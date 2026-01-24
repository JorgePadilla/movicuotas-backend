# frozen_string_literal: true

module Admin
  class DevicesController < ApplicationController
    def index
      @devices = policy_scope(Device).includes(:loan, :phone_model, loan: :customer).order(created_at: :desc)

      # Filter by activation status
      case params[:activation]
      when "activated"
        @devices = @devices.where.not(activated_at: nil)
      when "pending"
        @devices = @devices.where(activated_at: nil)
      end

      # Filter by lock status
      @devices = @devices.where(lock_status: params[:lock_status]) if params[:lock_status].present?

      # Search by IMEI, activation code, or customer name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @devices = @devices.left_joins(loan: :customer)
                           .where("devices.imei ILIKE ? OR devices.activation_code ILIKE ? OR customers.full_name ILIKE ?",
                                  search_term, search_term, search_term)
                           .distinct
      end

      # Paginate results (20 per page)
      @devices = @devices.page(params[:page]).per(20)

      # Stats for summary
      @total_devices = Device.count
      @activated_devices = Device.where.not(activated_at: nil).count
      @pending_activation = Device.where(activated_at: nil).count
      @locked_devices = Device.locked.count
    end

    def show
      @device = Device.find(params[:id])
      authorize @device
      @loan = @device.loan
      @customer = @loan&.customer
    end

    def reset_activation
      @device = Device.find(params[:id])
      authorize @device

      if @device.reset_activation!(current_user)
        redirect_to admin_device_path(@device), notice: "Activación reiniciada. El código #{@device.activation_code} puede usarse nuevamente."
      else
        redirect_to admin_device_path(@device), alert: "No se pudo reiniciar la activación. El dispositivo no estaba activado."
      end
    end
  end
end
