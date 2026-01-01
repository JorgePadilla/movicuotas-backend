import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import Spanish from "flatpickr/dist/l10n/es"

export default class extends Controller {
  static targets = ["input", "button"]
  static values = {
    max: String,
    min: String,
    placeholder: { type: String, default: "DD/MM/AAAA" },
    initialValue: String,
    dateFormat: { type: String, default: "Y-m-d" },
    altFormat: { type: String, default: "d/m/Y" },
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
      dateFormat: this.dateFormatValue, // Hidden input format for form submission: "Y-m-d" (ISO)
      altFormat: this.altFormatValue, // Visible display format: "d/m/Y" (Honduras format)
      altInput: this.altInputValue, // Show alternate input with formatted date
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
      onChange: (selectedDates, dateStr, instance) => {
        // Flatpickr automatically updates the input value
        // The input target now has the ISO date value in dateFormat (Y-m-d)
        // which is what Rails expects for the date field
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
      // Initialize Flatpickr (clearing input not needed - Flatpickr handles it)
      this.picker = flatpickr(this.inputTarget, options)

      // Set initial value if provided
      if (this.hasInitialValue && this.initialValue) {
        this.picker.setDate(this.initialValue, false)
      }

      // Set placeholder if provided (will apply to alt input)
      if (this.hasPlaceholderValue) {
        this.inputTarget.placeholder = this.placeholderValue
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