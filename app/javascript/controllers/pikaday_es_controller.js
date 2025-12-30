import { Controller } from "@hotwired/stimulus"
import Pikaday from "pikaday"

export default class extends Controller {
  static targets = ["input", "button", "dateInput"]
  static values = {
    max: String,
    min: String,
    placeholder: { type: String, default: "DD/MM/AAAA" },
    initialValue: String,
    format: { type: String, default: "DD/MM/YYYY" }
  }

  connect() {
    // Clean up any existing instance first
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }

    // Spanish locale configuration
    const i18n = {
      previousMonth: 'Mes anterior',
      nextMonth: 'Mes siguiente',
      months: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
      weekdays: ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'],
      weekdaysShort: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
    }

    // Configure options
    const options = {
      field: this.inputTarget,
      format: this.formatValue,
      i18n,
      showDaysInNextAndPreviousMonths: true,
      reposition: true,
      firstDay: 1, // Monday as first day of week
      onSelect: (date) => {
        if (date) {
          // Format DD/MM/YYYY for display
          const day = String(date.getDate()).padStart(2, '0')
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const year = date.getFullYear()
          const formattedDate = `${day}/${month}/${year}`
          // Set text input value
          this.inputTarget.value = formattedDate
          // Set hidden date input value in ISO format for form submission
          if (this.hasDateInputTarget) {
            const isoDate = date.toISOString().split('T')[0] // YYYY-MM-DD
            this.dateInputTarget.value = isoDate
          }
        }
      },
      onOpen: () => {
        // Add custom class to calendar for styling
        if (this.picker && this.picker.el) {
          this.picker.el.classList.add('pikaday-es-calendar')
        }
      },
      onClose: () => {
        // Remove custom class when calendar closes
        if (this.picker && this.picker.el) {
          this.picker.el.classList.remove('pikaday-es-calendar')
        }
      }
    }

    // Add min/max constraints if provided
    if (this.hasMinValue) {
      options.minDate = new Date(this.minValue)
    }
    if (this.hasMaxValue) {
      options.maxDate = new Date(this.maxValue)
    }

    try {
      // Initialize Pikaday
      this.picker = new Pikaday(options)

      // Set initial value if provided
      if (this.hasInitialValue && this.initialValue) {
        this.picker.setDate(this.initialValue, true)
        // Also set hidden date input value
        if (this.hasDateInputTarget) {
          this.dateInputTarget.value = this.initialValue
        }
      }

      // Set placeholder if provided
      if (this.hasPlaceholderValue) {
        this.inputTarget.placeholder = this.placeholderValue
      }

    } catch (error) {
      console.error("Failed to initialize Pikaday:", error)
    }
  }

  disconnect() {
    // Clean up Pikaday instance when controller is disconnected
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
  }

  show() {
    if (this.picker) {
      this.picker.show()
    }
  }
}