Rails.application.config.session_store :cookie_store,
  key: "_movicuotas_session",
  secure: true,
  same_site: :lax
