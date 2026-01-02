import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import Spanish from "flatpickr/dist/l10n/es"

export default class extends Controller {
  static targets = ["input", "button", "display"]
  static values = {
    max: String,
    min: String,
    placeholder: { type: String, default: "DD/MM/AAAA" },
    initialValue: String,
    dateFormat: { type: String, default: "Y-m-d" },
    altFormat: { type: String, default: "d/m/Y" }
  }

  connect() {
    const self = this

    // Clean up any existing instance first
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }

    // Configure Flatpickr with Spanish locale
    flatpickr.localize(Spanish.default || Spanish)

    // Configure options
    const options = {
      dateFormat: this.dateFormatValue, // Hidden input format for form submission: "Y-m-d" (ISO)
      altFormat: this.altFormatValue, // Visible display format: "d/m/Y" (Spanish format)
      altInput: false, // Don't create alt input - we have a manual one in HTML
      locale: "es",
      allowInput: true,
      clickOpens: true,
      disableMobile: false,
      inline: false, // Don't show calendar inline, only on click
      monthSelectorType: "dropdown", // Use dropdown for month/year selection
      showMonths: 1, // Show one month at a time
      prevArrow: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>',
      nextArrow: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>',
      // Ensure calendar is positioned correctly
      position: "absolute", // Position absolutely within the appendTo container
      onChange: (selectedDates, dateStr, instance) => {
        // Update the display input with Spanish-formatted date
        if (self.hasDisplayTarget && selectedDates.length > 0) {
          const date = selectedDates[0]
          // Format: DD/MM/YYYY
          const day = String(date.getDate()).padStart(2, '0')
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const year = date.getFullYear()
          self.displayTarget.value = `${day}/${month}/${year}`
        }
      },
      onOpen: (selectedDates, dateStr, instance) => {
        // Add custom class to calendar for styling
        const calendar = instance.calendarContainer
        if (calendar) {
          calendar.classList.add('flatpickr-es-calendar')

          // Position calendar below the display input
          if (self.hasDisplayTarget) {
            const displayRect = self.displayTarget.getBoundingClientRect()
            const parentRect = self.displayTarget.parentElement.getBoundingClientRect()

            // Set top position to be below the input
            calendar.style.top = (displayRect.bottom - parentRect.top + 8) + 'px'
            // Center horizontally relative to input
            calendar.style.left = (displayRect.left - parentRect.left) + 'px'
          }
        }
      },
      onClose: (selectedDates, dateStr, instance) => {
      },
      onReady: (selectedDates, dateStr, instance) => {
      }
    }


    // Add min/max constraints if provided
    if (this.hasMinValue) {
      options.minDate = this.minValue
    }
    if (this.hasMaxValue) {
      options.maxDate = this.maxValue
    }

    try {
      // Append calendar to the display input's parent for proper positioning
      if (this.hasDisplayTarget) {
        options.appendTo = this.displayTarget.parentElement
      }

      // Initialize Flatpickr on the hidden input but position relative to display
      this.picker = flatpickr(this.inputTarget, options)

      // Set initial value if provided
      if (this.hasInitialValue && this.initialValue) {
        this.picker.setDate(this.initialValue, false)

        // Also update the display input with the formatted date
        const date = new Date(this.initialValue)
        if (this.hasDisplayTarget && !isNaN(date.getTime())) {
          const day = String(date.getDate()).padStart(2, '0')
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const year = date.getFullYear()
          this.displayTarget.value = `${day}/${month}/${year}`
        }
      }

      // Set placeholder on display input
      if (this.hasPlaceholderValue && this.hasDisplayTarget) {
        this.displayTarget.placeholder = this.placeholderValue
      }

    } catch (error) {
      console.error("Failed to initialize Flatpickr:", error)
    }
  }

  // Open the date picker (called by button click)
  open() {
    if (this.picker) {
      this.picker.open()
    }
  }

  disconnect() {
    // Clean up Flatpickr instance when controller is disconnected
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
    // Trigger button removed - no cleanup needed
  }
}