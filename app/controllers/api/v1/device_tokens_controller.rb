# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < BaseController
      # POST /api/v1/device_tokens
      # Register or update a device token for push notifications
      def create
        # Find existing token or build new one
        device_token = DeviceToken.find_by(token: device_token_params[:token])

        if device_token
          # Token exists - update it (may have been invalidated)
          device_token.assign_attributes(device_token_params.merge(
            customer: current_customer,
            active: true,
            invalidated_at: nil,
            last_used_at: Time.current
          ))
        else
          # New token
          device_token = current_customer.device_tokens.build(
            device_token_params.merge(last_used_at: Time.current)
          )
        end

        if device_token.save
          render_success({
            message: "Device token registered successfully",
            device_token: {
              id: device_token.id,
              platform: device_token.platform,
              active: device_token.active,
              created_at: device_token.created_at
            }
          }, :created)
        else
          render_error(device_token.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # DELETE /api/v1/device_tokens
      # Unregister a device token (logout/uninstall)
      def destroy
        device_token = current_customer.device_tokens.find_by(token: params[:token])

        if device_token
          device_token.invalidate
          render_success({ message: "Device token unregistered successfully" })
        else
          render_error("Device token not found", :not_found)
        end
      end

      # PUT /api/v1/device_tokens/refresh
      # Update last_used_at timestamp (called on app open)
      def refresh
        device_token = current_customer.device_tokens.find_by(token: params[:token])

        if device_token
          device_token.mark_as_used
          render_success({ message: "Device token refreshed" })
        else
          render_error("Device token not found", :not_found)
        end
      end

      private

      def device_token_params
        params.require(:device_token).permit(
          :token,
          :platform,
          :device_name,
          :os_version,
          :app_version
        )
      end
    end
  end
end
