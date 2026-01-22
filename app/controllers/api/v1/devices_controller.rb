# frozen_string_literal: true

module Api
  module V1
    class DevicesController < BaseController
      skip_before_action :authenticate_api_user, only: [ :activate ]

      # POST /api/v1/devices/activate
      # Activates a device using an activation code and registers the FCM token
      def activate
        device = Device.find_by(activation_code: params[:activation_code]&.upcase)

        return render_error("Codigo de activacion invalido", :not_found) unless device
        return render_error("Este dispositivo ya fue activado", :unprocessable_entity) if device.activated?

        # Validate required parameters
        return render_error("Token FCM requerido", :bad_request) if params[:fcm_token].blank?

        # Create or update device token linked to device
        device_token = device.device_tokens.find_or_initialize_by(token: params[:fcm_token])
        device_token.assign_attributes(
          platform: params[:platform] || "android",
          device_name: params[:device_name],
          customer: device.loan&.customer,
          active: true,
          last_used_at: Time.current
        )

        if device_token.save
          device.activate!

          render_success({
            message: "Dispositivo activado correctamente"
          })
        else
          render_error(device_token.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end
    end
  end
end
