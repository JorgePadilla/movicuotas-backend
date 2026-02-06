module Api
  module V1
    class SettingsController < BaseController
      skip_before_action :authenticate_api_user

      def index
        support_phone = SystemSetting.get("support_phone_number")
        support_schedule = SystemSetting.get("support_schedule")
        render json: { support_phone_number: support_phone, support_schedule: support_schedule }
      end
    end
  end
end
