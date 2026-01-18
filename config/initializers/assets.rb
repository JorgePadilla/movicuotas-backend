# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add Mission Control Jobs assets to the load path
if defined?(MissionControl::Jobs)
  Rails.application.config.assets.paths << MissionControl::Jobs::Engine.root.join("app/assets/stylesheets")
  Rails.application.config.assets.paths << MissionControl::Jobs::Engine.root.join("app/assets/javascripts")
end
