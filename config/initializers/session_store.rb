Rails.application.config.session_store :cookie_store,
  key: "_movicuotas_session",
  secure: Rails.application.config.force_ssl,
  same_site: :lax
