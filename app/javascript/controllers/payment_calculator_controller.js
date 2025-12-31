// Stimulus controller for dynamic payment calculation
// Step 12: Payment Calculator - Vendor Workflow

import { Controller } from "@hotwired/stimulus"
// Turbo is available globally via importmap in application.js

export default class extends Controller {
  static targets = []  // No Stimulus targets needed, using getElementById
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

    // Sync continue form with initial values
    this.syncContinueForm()

    // Update continue button state based on existing results
    this.updateContinueButtonStateBasedOnDOM()

    // Calculate automatically if values are selected but no results shown yet
    this.calculateAutomaticallyIfNeeded()
  }

  // Check if we should calculate automatically on page load
  calculateAutomaticallyIfNeeded() {
    // Check if results are already shown (not placeholder)
    const resultsElement = document.getElementById('calculator_results')
    const hasResults = resultsElement && resultsElement.querySelector('.bg-white.shadow-lg')

    if (hasResults) {
      console.log("Results already shown, skipping auto-calculation")
      return
    }

    // Check if values are selected
    const downPaymentChecked = this.element.querySelector('input[name="down_payment_percentage"]:checked')
    const installmentsChecked = this.element.querySelector('input[name="number_of_installments"]:checked')

    if (!downPaymentChecked || !installmentsChecked) {
      console.log("No values selected, skipping auto-calculation")
      return
    }

    console.log("Values selected but no results shown, calculating automatically...")
    // Call calculate without event
    this.calculate()
  }

  // Calculate installment amount when any input changes
  calculate(event) {
    if (event) {
      event.preventDefault()
    }
    console.log("Payment calculator: calculate triggered")

    // Get form data
    const formData = new FormData(this.element)
    const formDataObj = Object.fromEntries(formData.entries())
    console.log("Form data:", formDataObj)

    // Sync continue form hidden fields with current values
    this.syncContinueForm()

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
        // Update continue button state based on response
        this.parseAndUpdateButtonState(html)
        // Turbo will handle the stream response
        console.log("Turbo object available:", typeof window.Turbo)
        console.log("renderStreamMessage available:", window.Turbo && typeof window.Turbo.renderStreamMessage)
        if (window.Turbo && window.Turbo.renderStreamMessage) {
          console.log("Calling Turbo.renderStreamMessage")
          try {
            window.Turbo.renderStreamMessage(html)
            console.log("Turbo.renderStreamMessage completed")
          } catch (error) {
            console.error("Error in Turbo.renderStreamMessage:", error)
            console.log("Falling back to manual DOM update")
            this.updateDOMWithResponse(html)
          }
          // Check if DOM was updated
          setTimeout(() => {
            const resultsElement = document.getElementById('calculator_results')
            console.log("After Turbo stream - results element:", resultsElement)
            console.log("InnerHTML length:", resultsElement ? resultsElement.innerHTML.length : 'no element')
            if (resultsElement) {
              // Check for installment amount in the results
              const installmentEl = resultsElement.querySelector('.text-5xl.font-bold.text-green-600')
              console.log("Installment element:", installmentEl)
              console.log("Installment text:", installmentEl ? installmentEl.textContent : 'not found')
            }
          }, 100)
        } else {
          console.error("Turbo.renderStreamMessage not available, falling back to DOM update")
          this.updateDOMWithResponse(html)
        }
        this.hideLoading()
      })
      .catch(error => {
        console.error("Error calculating payment:", error)
        this.showError("Error al calcular. Por favor, intenta nuevamente.")
        this.hideLoading()
      })
  }

  // Sync hidden fields in continue form with current calculator values
  syncContinueForm() {
    // Try multiple ways to find the continue form
    let continueForm = document.getElementById('continue_to_contract_form')
    if (!continueForm) {
      // Try by action attribute
      continueForm = document.querySelector('form[action*="vendor_payment_calculator"]:not([data-controller="payment-calculator"])')
    }
    if (!continueForm) {
      console.log("No continue form found, skipping sync")
      // Debug: log all forms on page
      const allForms = document.querySelectorAll('form')
      console.log("Available forms:", Array.from(allForms).map(f => ({ id: f.id, action: f.action, class: f.className })))
      return
    }

    console.log("Found continue form:", continueForm.id || continueForm.action)

    const formData = new FormData(this.element)

    // Update hidden fields in continue form
    const downPayment = formData.get('down_payment_percentage')
    const installments = formData.get('number_of_installments')

    console.log("Syncing continue form with values:", { downPayment, installments })

    // Update hidden inputs in continue form
    const downPaymentInput = continueForm.querySelector('input[name="down_payment_percentage"]')
    const installmentsInput = continueForm.querySelector('input[name="number_of_installments"]')

    if (downPaymentInput && downPayment) {
      downPaymentInput.value = downPayment
    }
    if (installmentsInput && installments) {
      installmentsInput.value = installments
    }

    // Also update phone_price and approved_amount just in case
    const phonePrice = formData.get('phone_price')
    const approvedAmount = formData.get('approved_amount')
    const dateOfBirth = formData.get('date_of_birth')

    const phonePriceInput = continueForm.querySelector('input[name="phone_price"]')
    const approvedAmountInput = continueForm.querySelector('input[name="approved_amount"]')
    const dateOfBirthInput = continueForm.querySelector('input[name="date_of_birth"]')

    if (phonePriceInput && phonePrice) phonePriceInput.value = phonePrice
    if (approvedAmountInput && approvedAmount) approvedAmountInput.value = approvedAmount
    if (dateOfBirthInput && dateOfBirth) dateOfBirthInput.value = dateOfBirth
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

  // Parse Turbo Stream HTML and update button state
  parseAndUpdateButtonState(html) {
    try {
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const turboStreams = doc.querySelectorAll('turbo-stream')

      let hasError = false
      let hasSuccess = false

      turboStreams.forEach(stream => {
        const target = stream.getAttribute('target')
        if (target === 'calculator_errors') {
          hasError = true
        } else if (target === 'calculator_results') {
          hasSuccess = true
        }
      })

      this.updateContinueButtonState(hasSuccess && !hasError)
    } catch (error) {
      console.error("Error parsing Turbo Stream response:", error)
    }
  }

  // Update continue button state based on existing DOM state
  updateContinueButtonStateBasedOnDOM() {
    // Check if calculator_results contains success content (not placeholder)
    const resultsElement = document.getElementById('calculator_results')
    const errorsElement = document.getElementById('calculator_errors')

    let enabled = false
    if (resultsElement && resultsElement.querySelector('.bg-white.shadow-lg')) {
      // Success results partial is present
      enabled = true
    } else if (errorsElement && errorsElement.querySelector('.bg-red-50')) {
      // Error partial is present
      enabled = false
    } else {
      // No results yet, check if continue form is already visible
      const continueForm = document.getElementById('continue_to_contract_form')
      enabled = continueForm && !continueForm.classList.contains('hidden')
    }

    this.updateContinueButtonState(enabled)
  }

  // Update continue button state based on calculation success
  updateContinueButtonState(enabled) {
    // Find elements by ID (not using Stimulus targets for broader scope)
    const continueForm = document.getElementById('continue_to_contract_form')
    const disabledButton = document.getElementById('disabled_continue_button')

    if (!continueForm || !disabledButton) {
      console.log("Continue form or disabled button not found, skipping state update")
      return
    }

    if (enabled) {
      // Enable the submit button and show the form
      continueForm.classList.remove('hidden')
      disabledButton.classList.add('hidden')
    } else {
      // Disable the submit button and show disabled button
      continueForm.classList.add('hidden')
      disabledButton.classList.remove('hidden')
    }
  }

  // Fallback method to update DOM when Turbo.renderStreamMessage is not available
  updateDOMWithResponse(html) {
    console.log("Fallback: manually parsing Turbo Stream response")
    try {
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const turboStreams = doc.querySelectorAll('turbo-stream')

      if (turboStreams.length === 0) {
        console.error("No turbo-stream elements found in response")
        return
      }

      let hasError = false
      let hasSuccess = false

      turboStreams.forEach(stream => {
        const action = stream.getAttribute('action')
        const target = stream.getAttribute('target')
        const template = stream.querySelector('template')

        // Track error/success for button state
        if (target === 'calculator_errors') {
          hasError = true
        } else if (target === 'calculator_results') {
          hasSuccess = true
        }

        if (!template || !target) {
          console.error("Invalid turbo-stream element:", stream)
          return
        }

        const targetElement = document.getElementById(target)
        if (!targetElement) {
          console.error("Target element not found:", target)
          return
        }

        const content = template.innerHTML

        switch (action) {
          case 'replace':
            targetElement.innerHTML = content
            break
          case 'append':
            targetElement.insertAdjacentHTML('beforeend', content)
            break
          case 'prepend':
            targetElement.insertAdjacentHTML('afterbegin', content)
            break
          case 'remove':
            targetElement.remove()
            break
          case 'before':
            targetElement.insertAdjacentHTML('beforebegin', content)
            break
          case 'after':
            targetElement.insertAdjacentHTML('afterend', content)
            break
          default:
            console.error("Unknown turbo-stream action:", action)
        }
      })

      // Update button state based on success/error
      this.updateContinueButtonState(hasSuccess && !hasError)
    } catch (error) {
      console.error("Error parsing Turbo Stream response:", error)
      this.showError("Error al procesar la respuesta del servidor.")
    }
  }
}