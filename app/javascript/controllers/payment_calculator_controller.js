// Stimulus controller for dynamic payment calculation
// Step 12: Payment Calculator - Vendor Workflow

import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["downPayment", "installmentTerm"]
  static values = {
    calculateUrl: String
  }

  connect() {
    console.log("Payment calculator controller connected")
    // Set the calculate URL if not already set
    if (!this.hasCalculateUrlValue) {
      this.calculateUrlValue = this.element.dataset.calculateUrl || "/vendor/payment_calculator/calculate"
    }
    console.log("Calculate URL:", this.calculateUrlValue)
  }

  // Calculate installment amount when any input changes
  calculate(event) {
    event.preventDefault()
    console.log("Payment calculator: calculate triggered")

    // Get form data
    const formData = new FormData(this.element)
    const formDataObj = Object.fromEntries(formData.entries())
    console.log("Form data:", formDataObj)

    // Show loading state
    this.showLoading()

    // Send Turbo Stream request
    console.log("Sending request to:", this.calculateUrlValue)
    fetch(this.calculateUrlValue, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": this.getCSRFToken()
      },
      body: new URLSearchParams(formData)
    })
      .then(response => {
        console.log("Response status:", response.status, response.statusText)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.text()
      })
      .then(html => {
        console.log("Received Turbo Stream HTML length:", html.length)
        console.log("HTML preview:", html.substring(0, 200))
        // Turbo will handle the stream response
        Turbo.renderStreamMessage(html)
        this.hideLoading()
      })
      .catch(error => {
        console.error("Error calculating payment:", error)
        this.showError("Error al calcular. Por favor, intenta nuevamente.")
        this.hideLoading()
      })
  }

  // Get CSRF token from meta tag
  getCSRFToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }

  // Show loading indicator
  showLoading() {
    const resultsFrame = document.getElementById("calculator_results")
    if (resultsFrame) {
      resultsFrame.innerHTML = `
        <div class="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-[#125282]"></div>
          <p class="mt-4 text-gray-600">Calculando cuota quincenal...</p>
        </div>
      `
    }
  }

  // Hide loading indicator
  hideLoading() {
    // Loading state is replaced by Turbo Stream response
  }

  // Show error message
  showError(message) {
    const errorsDiv = document.getElementById("calculator_errors")
    if (errorsDiv) {
      errorsDiv.innerHTML = `
        <div class="bg-red-50 border border-red-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-600" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-red-800">${message}</p>
            </div>
          </div>
        </div>
      `
    }
  }
}