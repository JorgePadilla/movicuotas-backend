# frozen_string_literal: true

module Admin
  class SettingsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize nil, policy_class: Admin::SettingsPolicy
      @support_phone_number = SystemSetting.get("support_phone_number") || ""
    end

    def update
      authorize nil, policy_class: Admin::SettingsPolicy

      phone = params[:support_phone_number]&.strip
      if phone.present?
        SystemSetting.set("support_phone_number", phone)
        redirect_to admin_settings_path, notice: "Configuración actualizada exitosamente."
      else
        @support_phone_number = phone
        flash.now[:alert] = "El número de teléfono de soporte no puede estar vacío."
        render :index, status: :unprocessable_entity
      end
    end

    private

    def pundit_policy_class
      Admin::SettingsPolicy
    end
  end
end
