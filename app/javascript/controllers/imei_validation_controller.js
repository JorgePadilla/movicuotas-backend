import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "feedback"]
  static values = {
    checkUrl: { type: String, default: "/api/v1/devices/check_imei" }
  }

  connect() {
    this.debounceTimer = null
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  validate(event) {
    const imei = event.target.value.trim()
    this.clearFeedback()

    if (imei.length === 0) return

    // Only allow digits
    if (!/^\d+$/.test(imei)) {
      this.showError("IMEI solo debe contener numeros")
      return
    }

    if (imei.length < 15) {
      this.showWarning(`Faltan ${15 - imei.length} digitos`)
      return
    }

    if (imei.length === 15) {
      // Debounce the API call
      if (this.debounceTimer) {
        clearTimeout(this.debounceTimer)
      }
      this.debounceTimer = setTimeout(() => {
        this.checkAvailability(imei)
      }, 300)
    }

    if (imei.length > 15) {
      this.showError("IMEI no puede tener mas de 15 digitos")
    }
  }

  async checkAvailability(imei) {
    this.showLoading()

    try {
      const response = await fetch(`${this.checkUrlValue}?imei=${imei}`)
      const data = await response.json()

      if (data.data && data.data.available) {
        this.showSuccess(data.data.message || "IMEI disponible")
      } else if (data.data) {
        this.showError(data.data.message || "IMEI no disponible")
      } else {
        this.showError("Error al verificar IMEI")
      }
    } catch (error) {
      this.showError("Error al verificar IMEI")
    }
  }

  clearFeedback() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = ""
      this.feedbackTarget.className = "mt-1 text-sm"
    }
  }

  showLoading() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = "Verificando..."
      this.feedbackTarget.className = "mt-1 text-sm text-gray-500"
    }
  }

  showSuccess(message) {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = "✓ " + message
      this.feedbackTarget.className = "mt-1 text-sm text-green-600"
    }
  }

  showWarning(message) {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = message
      this.feedbackTarget.className = "mt-1 text-sm text-yellow-600"
    }
  }

  showError(message) {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = "✗ " + message
      this.feedbackTarget.className = "mt-1 text-sm text-red-600"
    }
  }
}
