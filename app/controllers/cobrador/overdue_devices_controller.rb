# frozen_string_literal: true

module Cobrador
  class OverdueDevicesController < ApplicationController
    before_action :set_filters, only: :index
    before_action :set_device, only: [:show, :block, :confirm_block]

    def index
      authorize Device, policy_class: DevicePolicy
      @devices = fetch_overdue_devices
      @min_days = params[:min_days].to_i if params[:min_days].present?
      @min_amount = params[:min_amount].to_f if params[:min_amount].present?
    end

    def show
      authorize @device, :show?, policy_class: DevicePolicy
      @device_details = fetch_device_details(@device)
    end

    def block
      authorize @device, :lock?, policy_class: DevicePolicy

      if @device.unlocked?
        @device_details = fetch_device_details(@device)
        # Show confirmation page
        render :block_confirmation
      else
        redirect_to cobrador_overdue_device_path(@device),
                    alert: "Este dispositivo ya está bloqueado o en proceso de bloqueo."
      end
    end

    def confirm_block
      authorize @device, :lock?, policy_class: DevicePolicy

      service = MdmBlockService.new(@device, current_user)
      result = service.block!

      if result[:success]
        redirect_to cobrador_overdue_device_path(@device),
                    notice: result[:message]
      else
        redirect_to cobrador_overdue_device_path(@device),
                    alert: result[:error]
      end
    end

    private

    def set_device
      @device = Device.find(params[:id])
    end

    def set_filters
      @min_days = params[:min_days].to_i if params[:min_days].present?
      @min_amount = params[:min_amount].to_f if params[:min_amount].present?
      @branch_filter = params[:branch] if params[:branch].present?
    end

    def fetch_overdue_devices
      devices = Device.joins(loan: :installments)
                      .where(installments: { status: "overdue" })
                      .select(
                        "devices.*",
                        "loans.contract_number",
                        "customers.full_name as customer_name",
                        "COUNT(DISTINCT installments.id) as overdue_count",
                        "SUM(installments.amount) as total_overdue",
                        "MIN(installments.due_date) as first_overdue_date",
                        "(CURRENT_DATE - MIN(installments.due_date)) as days_overdue"
                      )
                      .group("devices.id, loans.id, customers.id")

      # Apply filters
      devices = devices.where("(CURRENT_DATE - MIN(installments.due_date)) >= ?", @min_days) if @min_days.present? && @min_days > 0
      devices = devices.having("SUM(installments.amount) >= ?", @min_amount) if @min_amount.present? && @min_amount > 0
      devices = devices.where(loans: { branch_number: @branch_filter }) if @branch_filter.present?

      devices.order("days_overdue DESC, total_overdue DESC")
    end

    def fetch_device_details(device)
      {
        device: {
          imei: device.imei,
          brand: device.brand,
          model: device.model,
          lock_status: device.lock_status,
          locked_at: device.locked_at
        },
        customer: {
          name: device.loan&.customer&.full_name,
          phone: device.loan&.customer&.phone,
          identification: device.loan&.customer&.identification_number
        },
        loan: {
          contract_number: device.loan&.contract_number,
          status: device.loan&.status
        },
        overdue: {
          installments: device.loan&.installments&.overdue&.order(:due_date),
          total_overdue: device.loan&.installments&.overdue&.sum(:amount).to_f || 0.0,
          days_since_first: calculate_days_overdue(device.loan)
        },
        upcoming: device.loan&.installments&.pending&.order(:due_date)&.limit(3)
      }
    end

    def calculate_days_overdue(loan)
      return 0 unless loan
      first_overdue = loan.installments.overdue.minimum(:due_date)
      return 0 unless first_overdue
      (Date.today - first_overdue).to_i
    end
  end
end
