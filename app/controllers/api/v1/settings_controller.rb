module Api
  module V1
    class SettingsController < BaseController
      skip_before_action :authenticate_api_user

      def index
        support_phone = SystemSetting.get("support_phone_number")
        render json: { support_phone_number: support_phone }
      end
    end
  end
end
