# frozen_string_literal: true

module Supervisor
  class OverdueDevicesController < ApplicationController
    before_action :set_filters, only: :index
    before_action :set_device, only: [ :show, :block, :confirm_block ]

    PER_PAGE_OPTIONS = [ 10, 25, 50 ].freeze
    DEFAULT_PER_PAGE = 25
    SORT_COLUMNS = %w[days_overdue total_overdue customer_name first_overdue_date].freeze
    DEFAULT_SORT = "days_overdue"

    def index
      authorize Device, :index?, policy_class: DevicePolicy
      skip_policy_scope
      @devices = fetch_overdue_devices
      @total_overdue_amount = calculate_total_overdue_amount
      @total_overdue_count = @devices.total_count
      @per_page_options = PER_PAGE_OPTIONS
      @current_per_page = @per_page
      @min_days = params[:min_days].to_i if params[:min_days].present?
      @min_amount = params[:min_amount].to_f if params[:min_amount].present?

      # Support CSV export
      respond_to do |format|
        format.html
        format.csv { send_csv_export }
      end
    end

    def show
      authorize @device, :show?, policy_class: DevicePolicy
      @device_details = fetch_device_details(@device)
    end

    def block
      authorize @device, :lock?, policy_class: DevicePolicy

      if @device.unlocked?
        @device_details = fetch_device_details(@device)
        render :block_confirmation
      else
        redirect_to supervisor_overdue_device_path(@device),
                    alert: "Este dispositivo ya está bloqueado o en proceso de bloqueo."
      end
    end

    def confirm_block
      authorize @device, :lock?, policy_class: DevicePolicy

      service = MdmBlockService.new(@device, current_user)
      result = service.block!

      if result[:success]
        redirect_to supervisor_overdue_device_path(@device),
                    notice: result[:message]
      else
        redirect_to supervisor_overdue_device_path(@device),
                    alert: result[:error]
      end
    end

    def confirm_unblock
      authorize @device, :unlock?, policy_class: DevicePolicy

      service = MdmBlockService.new(@device, current_user)
      result = service.unblock!

      if result[:success]
        redirect_to supervisor_overdue_device_path(@device),
                    notice: result[:message]
      else
        redirect_to supervisor_overdue_device_path(@device),
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
      @imei_search = params[:imei] if params[:imei].present?
      @customer_search = params[:customer] if params[:customer].present?
      @days_range = parse_days_range
      @per_page = validate_per_page(params[:per_page])
      @sort_column = validate_sort_column(params[:sort])
      @sort_order = validate_sort_order(params[:order])
    end

    def fetch_overdue_devices
      devices = Device.joins(loan: [ :installments, :customer ])
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
      devices = apply_filter_min_days(devices)
      devices = apply_filter_min_amount(devices)
      devices = apply_filter_branch(devices)
      devices = apply_filter_imei(devices)
      devices = apply_filter_customer(devices)
      devices = apply_filter_days_range(devices)

      # Apply sorting
      devices = apply_sorting(devices)

      # Apply pagination
      devices.page(params[:page]).per(@per_page)
    end

    def apply_filter_min_days(devices)
      return devices unless @min_days.present? && @min_days > 0
      devices.having("(CURRENT_DATE - MIN(installments.due_date)) >= ?", @min_days)
    end

    def apply_filter_min_amount(devices)
      return devices unless @min_amount.present? && @min_amount > 0
      devices.having("SUM(installments.amount) >= ?", @min_amount)
    end

    def apply_filter_branch(devices)
      return devices unless @branch_filter.present?
      devices.where(loans: { branch_number: @branch_filter })
    end

    def apply_filter_imei(devices)
      return devices unless @imei_search.present?
      devices.where("devices.imei ILIKE ?", "%#{@imei_search}%")
    end

    def apply_filter_customer(devices)
      return devices unless @customer_search.present?
      devices.where("customers.full_name ILIKE ?", "%#{@customer_search}%")
    end

    def apply_filter_days_range(devices)
      return devices unless @days_range.present?
      min_days, max_days = @days_range
      devices.having("(CURRENT_DATE - MIN(installments.due_date)) BETWEEN ? AND ?", min_days, max_days)
    end

    def apply_sorting(devices)
      # Use explicit SQL strings to avoid Brakeman SQL injection warnings
      # @sort_order is validated to only be "ASC" or "DESC" by validate_sort_order
      order_sql = case @sort_column
      when "days_overdue"
                    @sort_order == "ASC" ? "(CURRENT_DATE - MIN(installments.due_date)) ASC" : "(CURRENT_DATE - MIN(installments.due_date)) DESC"
      when "total_overdue"
                    @sort_order == "ASC" ? "SUM(installments.amount) ASC" : "SUM(installments.amount) DESC"
      when "customer_name"
                    @sort_order == "ASC" ? "customers.full_name ASC" : "customers.full_name DESC"
      when "first_overdue_date"
                    @sort_order == "ASC" ? "MIN(installments.due_date) ASC" : "MIN(installments.due_date) DESC"
      else
                    "(CURRENT_DATE - MIN(installments.due_date)) DESC"
      end
      devices.order(Arel.sql(order_sql))
    end

    def parse_days_range
      case params[:days_range]
      when "1-7"
        [ 1, 7 ]
      when "8-15"
        [ 8, 15 ]
      when "16-30"
        [ 16, 30 ]
      when "30+"
        [ 31, 999 ]
      else
        nil
      end
    end

    def validate_per_page(per_page)
      per_page = per_page.to_i if per_page.present?
      return DEFAULT_PER_PAGE unless per_page&.positive? && PER_PAGE_OPTIONS.include?(per_page)
      per_page
    end

    def validate_sort_column(sort_column)
      return DEFAULT_SORT unless sort_column.present? && SORT_COLUMNS.include?(sort_column)
      sort_column
    end

    def validate_sort_order(sort_order)
      return "DESC" unless sort_order.present? && %w[ASC DESC asc desc].include?(sort_order)
      sort_order.upcase
    end

    def calculate_total_overdue_amount
      Device.joins(loan: :installments)
            .where(installments: { status: "overdue" })
            .sum("installments.amount").to_f || 0.0
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

    def send_csv_export
      # Get unpaginated devices for full export
      all_devices = Device.joins(loan: [ :installments, :customer ])
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

      all_devices = apply_filter_min_days(all_devices)
      all_devices = apply_filter_min_amount(all_devices)
      all_devices = apply_filter_branch(all_devices)
      all_devices = apply_filter_imei(all_devices)
      all_devices = apply_filter_customer(all_devices)
      all_devices = apply_filter_days_range(all_devices)
      all_devices = apply_sorting(all_devices)

      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      filename = "overdue_devices_#{timestamp}.csv"

      send_data generate_csv(all_devices),
                filename: filename,
                type: "text/csv"
    end

    def generate_csv(devices)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << [
          "Cliente",
          "IMEI",
          "Marca",
          "Modelo",
          "Contrato",
          "Cuotas Vencidas",
          "Monto (L.)",
          "Primer Vencimiento",
          "Días de Atraso",
          "Estado Bloqueo",
          "Bloqueado En"
        ]

        devices.each do |device|
          csv << [
            device.customer_name,
            device.imei,
            device.brand,
            device.model,
            device.contract_number,
            device.overdue_count,
            number_with_precision(device.total_overdue || 0, precision: 2),
            device.first_overdue_date&.strftime("%d/%m/%Y"),
            device.days_overdue,
            device.lock_status.capitalize,
            device.locked_at&.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end
    end
  end
end
