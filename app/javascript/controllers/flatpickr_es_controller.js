import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import Spanish from "flatpickr/dist/l10n/es"

export default class extends Controller {
  static targets = ["input"]
  static values = {
    max: String,
    min: String,
    placeholder: { type: String, default: "DD/MM/AAAA" },
    initialValue: String,
    dateFormat: { type: String, default: "dd/mm/yyyy" },
    altFormat: { type: String, default: "dd/mm/yyyy" },
    altInput: { type: Boolean, default: false }
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
      dateFormat: this.dateFormatValue, // Display and submission format: "dd/mm/yyyy"
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
      position: "auto", // "auto" positions relative to input
      defaultDate: "2000-07-01", // Default calendar view: July 1, 2000
      onChange: (selectedDates, dateStr, instance) => {

        // Always ensure the date is formatted correctly using the selected Date object
        if (selectedDates.length > 0) {
          const date = selectedDates[0]
          const day = String(date.getDate()).padStart(2, '0')
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const year = date.getFullYear()
          const correctDate = `${day}/${month}/${year}`

          // Check if the displayed date string is corrupted
          if (dateStr !== correctDate) {
            console.warn("Date corruption detected:", dateStr, "-> correcting to:", correctDate)

            // Check for specific corruption patterns
            const yearPart = dateStr.split('/')[2]
            if (yearPart && yearPart.length === 4 && yearPart.slice(0, 2) === yearPart.slice(2, 4)) {
              console.warn("Year duplication detected:", yearPart)
            }

            // Set the correct date in the input
            self.inputTarget.value = correctDate

            // Update Flatpickr's internal state to prevent infinite loop
            instance.setDate(date, false)
          }
        }
      },
      onOpen: (selectedDates, dateStr, instance) => {
        // Add custom class to calendar for styling
        const calendar = instance.calendarContainer
        if (calendar) {
          calendar.classList.add('flatpickr-es-calendar')
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
      // Clear input value to prevent Flatpickr from corrupting existing value
      this.inputTarget.value = ''

      // Initialize Flatpickr
      this.picker = flatpickr(this.inputTarget, options)

      // Set initial value if provided (after initialization to avoid corruption)
      if (this.hasInitialValue && this.initialValue) {
        this.picker.setDate(this.initialValue, false)
      }

      // Set placeholder if provided
      if (this.hasPlaceholderValue) {
        this.inputTarget.placeholder = this.placeholderValue
      }

    } catch (error) {
      console.error("Failed to initialize Flatpickr:", error)
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