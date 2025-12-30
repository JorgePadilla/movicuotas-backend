# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "flatpickr" # @4.6.13
pin "flatpickr/dist/flatpickr.css", to: "flatpickr--dist--flatpickr.css.js" # @4.6.13
pin "flatpickr/dist/l10n/es", to: "flatpickr--dist--l10n--es.js" # @4.6.13
pin "stimulus-flatpickr" # @1.4.0
pin "stimulus" # @3.2.2
pin "pikaday" # @1.8.2
pin "moment" # @2.30.1
pin "pikaday/css/pikaday.css", to: "pikaday--css--pikaday.css.js" # @1.8.2
