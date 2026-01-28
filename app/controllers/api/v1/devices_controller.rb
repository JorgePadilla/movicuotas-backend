# frozen_string_literal: true

module Api
  module V1
    class DevicesController < BaseController
      skip_before_action :authenticate_api_user, only: [ :activate, :check_imei ]

      # POST /api/v1/devices/activate
      # Activates a device using an activation code and registers the FCM token
      def activate
        device = Device.find_by(activation_code: params[:activation_code]&.upcase)

        return render_error("Codigo de activacion invalido", :not_found) unless device
        return render_error("Este dispositivo ya fue activado", :unprocessable_entity) if device.activated?

        # Validate required parameters
        return render_error("Token FCM requerido", :bad_request) if params[:fcm_token].blank?

        loan = device.loan
        customer = loan&.customer

        # Create or update device token linked to device
        device_token = device.device_tokens.find_or_initialize_by(token: params[:fcm_token])
        device_token.assign_attributes(
          platform: params[:platform] || "android",
          device_name: params[:device_name],
          customer: customer,
          active: true,
          last_used_at: Time.current
        )

        if device_token.save
          device.activate!

          # Build response with customer and loan data
          response_data = {
            message: "Dispositivo activado correctamente",
            activated_at: device.activated_at.iso8601
          }

          # Generate JWT token for the customer (allows app to skip login)
          if customer
            response_data[:token] = generate_token(customer)
          end

          if customer
            response_data[:customer] = {
              id: customer.id,
              full_name: customer.full_name,
              phone: customer.phone
            }
          end

          if loan
            next_installment = loan.next_installment
            response_data[:loan] = {
              id: loan.id,
              contract_number: loan.contract_number,
              total_amount: loan.total_amount.to_f,
              remaining_balance: loan.remaining_balance.to_f,
              status: loan.status
            }

            if next_installment
              response_data[:loan][:next_payment_date] = next_installment.due_date.iso8601
              response_data[:loan][:next_payment_amount] = next_installment.amount.to_f
            end
          end

          render_success(response_data)
        else
          render_error(device_token.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # GET /api/v1/devices/check_imei?imei=xxx
      # Checks if an IMEI is available for use (for vendor device selection)
      def check_imei
        imei = params[:imei]&.strip

        unless imei.present? && imei.match?(/\A\d{15}\z/)
          return render_success({ available: false, message: "IMEI debe tener 15 dígitos numéricos" })
        end

        existing_device = Device.find_by(imei: imei)

        if existing_device.nil?
          render_success({ available: true, message: "IMEI disponible" })
        else
          render_success({ available: false, message: "IMEI ya registrado en otro préstamo" })
        end
      end

      private

      def generate_token(customer)
        payload = {
          customer_id: customer.id,
          exp: 30.days.from_now.to_i,
          iat: Time.now.to_i
        }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end
    end
  end
end
