import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textInput", "dateInput", "calendarButton"]
  static values = {
    max: String,
    min: String,
    placeholder: { type: String, default: "DD/MM/AAAA" },
    initialValue: String
  }

  connect() {

    // Set min/max on date input if provided
    if (this.hasMaxValue) {
      this.dateInputTarget.max = this.maxValue
    }
    if (this.hasMinValue) {
      this.dateInputTarget.min = this.minValue
    }

    // Set placeholder on text input
    if (this.hasPlaceholderValue) {
      this.textInputTarget.placeholder = this.placeholderValue
    }

    // Set initial value if provided
    if (this.hasInitialValue && this.initialValue) {
      this.dateInputTarget.value = this.initialValue
      this.syncDateToText()
    }

    // Add event listeners for real-time syncing
    this.textInputTarget.addEventListener('input', this.syncTextToDate.bind(this))
    this.textInputTarget.addEventListener('change', this.syncTextToDate.bind(this))
    this.dateInputTarget.addEventListener('change', this.syncDateToText.bind(this))

    // Sync any existing date value to text input on initialization
    this.syncDateToText()
  }

  // When date input changes (user picked a date in calendar), update text input
  syncDateToText() {
    const dateValue = this.dateInputTarget.value

    if (!dateValue) {
      this.textInputTarget.value = ''
      return
    }

    const [year, month, day] = dateValue.split('-')
    this.textInputTarget.value = `${day}/${month}/${year}`
  }

  // When text input changes (user typed), try to parse and update date input
  syncTextToDate() {
    const textValue = this.textInputTarget.value.trim()

    if (!textValue) {
      this.dateInputTarget.value = ''
      return
    }

    // Try to parse DD/MM/YYYY
    const match = textValue.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/)
    if (match) {
      let [, day, month, year] = match

      // Pad single digits with leading zeros
      day = day.padStart(2, '0')
      month = month.padStart(2, '0')

      const isoDate = `${year}-${month}-${day}`

      // Validate date
      const date = new Date(isoDate)
      if (!isNaN(date.getTime())) {
        this.dateInputTarget.value = isoDate
        return
      }
    }

    // If parsing fails, clear date input
    this.dateInputTarget.value = ''
  }

  // Open the native date picker
  openDatePicker() {

    // Create a wrapper div with Spanish locale
    const wrapper = document.createElement('div')
    wrapper.lang = 'es'
    wrapper.style.position = 'fixed'
    wrapper.style.top = '0'
    wrapper.style.left = '0'
    wrapper.style.width = '0'
    wrapper.style.height = '0'
    wrapper.style.overflow = 'hidden'
    wrapper.style.zIndex = '9999'

    // Create a temporary date input element
    const tempDateInput = document.createElement('input')
    tempDateInput.type = 'date'
    tempDateInput.lang = 'es'
    tempDateInput.style.position = 'absolute'
    tempDateInput.style.top = '0'
    tempDateInput.style.left = '0'
    tempDateInput.style.width = '100%'
    tempDateInput.style.height = '100%'
    tempDateInput.style.opacity = '0'
    tempDateInput.style.pointerEvents = 'auto'

    // Copy min/max values from the original date input
    if (this.dateInputTarget.min) {
      tempDateInput.min = this.dateInputTarget.min
    }
    if (this.dateInputTarget.max) {
      tempDateInput.max = this.dateInputTarget.max
    }

    // Copy current value from the original date input
    if (this.dateInputTarget.value) {
      tempDateInput.value = this.dateInputTarget.value
    }

    // Add input to wrapper, wrapper to body
    wrapper.appendChild(tempDateInput)
    document.body.appendChild(wrapper)

    // Function to clean up
    const cleanup = () => {
      tempDateInput.removeEventListener('change', handleDateChange)
      tempDateInput.removeEventListener('blur', handleBlur)
      document.removeEventListener('keydown', handleEscape)

      if (wrapper.parentNode) {
        wrapper.parentNode.removeChild(wrapper)
      }
    }

    // Handle date selection
    const handleDateChange = (event) => {
      // Update the original date input
      this.dateInputTarget.value = tempDateInput.value
      // Sync to text input
      this.syncDateToText()
      // Clean up
      cleanup()
    }

    // Handle blur (calendar closed)
    const handleBlur = () => {
      // Small delay to allow change event to fire first
      setTimeout(() => {
        cleanup()
      }, 200)
    }

    // Handle Escape key
    const handleEscape = (event) => {
      if (event.key === 'Escape') {
        cleanup()
      }
    }

    // Add event listeners
    tempDateInput.addEventListener('change', handleDateChange)
    tempDateInput.addEventListener('blur', handleBlur)
    document.addEventListener('keydown', handleEscape)

    // Focus and open picker
    setTimeout(() => {
      tempDateInput.focus()

      // Use showPicker() if available (modern browsers)
      if (typeof tempDateInput.showPicker === 'function') {
        tempDateInput.showPicker()
      } else {
        tempDateInput.click()
      }
    }, 10)
  }

  // Validate the current date
  validate() {
    return this.dateInputTarget.checkValidity() && this.textInputTarget.checkValidity()
  }
}