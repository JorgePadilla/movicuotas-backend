# frozen_string_literal: true

module Supervisor
  class BulkOperationsController < ApplicationController
    def show
      @device_ids = params[:device_ids]&.split(",") || []
      @devices = fetch_selected_devices(@device_ids)
      @total_amount = @devices.sum { |d| d.total_overdue.to_f }
    end

    def confirm_bulk_block
      @device_ids = params[:device_ids]&.split(",") || []
      @devices = fetch_selected_devices(@device_ids)

      authorize Device, policy_class: DevicePolicy

      results = {
        success: [],
        failed: []
      }

      ActiveRecord::Base.transaction do
        @devices.each do |device|
          next if device.lock_status != "unlocked"

          service = MdmBlockService.new(device, current_user)
          result = service.block!

          if result[:success]
            results[:success] << device.imei
          else
            results[:failed] << { imei: device.imei, error: result[:error] }
          end
        end
      end

      if results[:failed].empty?
        redirect_to supervisor_overdue_devices_path,
                    notice: "#{results[:success].count} dispositivos bloqueados correctamente"
      else
        flash.now[:alert] = "#{results[:failed].count} dispositivos no pudieron bloquearse"
        @failed_devices = results[:failed]
        render :confirm_bulk_block
      end
    end

    private

    def fetch_selected_devices(device_ids)
      return [] if device_ids.blank?

      Device.joins(loan: :installments)
            .where(installments: { status: "overdue" })
            .where(devices: { id: device_ids })
            .select(
              "devices.*",
              "loans.contract_number",
              "customers.full_name as customer_name",
              "SUM(installments.amount) as total_overdue"
            )
            .group("devices.id, loans.id, customers.id")
            .distinct
    end
  end
end
