import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "inputContainer",
    "hiddenInput",
    "timer",
    "countdown",
    "error",
    "submitBtn",
    "resendBtn",
    "resendTimer",
    "resendCountdown"
  ]

  static values = {
    timeRemaining: { type: Number, default: 600 },  // 10 minutes in seconds
    resendCooldown: { type: Number, default: 0 }
  }

  connect() {
    this.startExpirationTimer()
    this.startResendTimer()
    this.focusFirstInput()
  }

  disconnect() {
    this.stopTimers()
  }

  // Input handling
  handleInput(event) {
    const input = event.target
    const value = input.value

    // Allow only digits
    if (!/^\d*$/.test(value)) {
      input.value = ""
      return
    }

    // Move to next input
    if (value.length === 1) {
      const nextInput = this.getNextInput(input)
      if (nextInput) {
        nextInput.focus()
      }
    }

    this.updateHiddenInput()
  }

  handleKeydown(event) {
    const input = event.target

    // Handle backspace
    if (event.key === "Backspace" && input.value === "") {
      const prevInput = this.getPrevInput(input)
      if (prevInput) {
        prevInput.focus()
        prevInput.value = ""
      }
    }

    // Handle arrow keys
    if (event.key === "ArrowLeft") {
      const prevInput = this.getPrevInput(input)
      if (prevInput) prevInput.focus()
    }

    if (event.key === "ArrowRight") {
      const nextInput = this.getNextInput(input)
      if (nextInput) nextInput.focus()
    }
  }

  handlePaste(event) {
    event.preventDefault()
    const pastedData = (event.clipboardData || window.clipboardData).getData("text")
    const digits = pastedData.replace(/\D/g, "").slice(0, 4)

    const inputs = this.inputContainerTarget.querySelectorAll("input")
    digits.split("").forEach((digit, index) => {
      if (inputs[index]) {
        inputs[index].value = digit
      }
    })

    // Focus last filled or next empty input
    const lastFilledIndex = Math.min(digits.length - 1, 3)
    if (inputs[lastFilledIndex + 1]) {
      inputs[lastFilledIndex + 1].focus()
    } else if (inputs[lastFilledIndex]) {
      inputs[lastFilledIndex].focus()
    }

    this.updateHiddenInput()
  }

  // Helper methods
  getNextInput(currentInput) {
    const currentIndex = parseInt(currentInput.dataset.index)
    return this.inputContainerTarget.querySelector(`input[data-index="${currentIndex + 1}"]`)
  }

  getPrevInput(currentInput) {
    const currentIndex = parseInt(currentInput.dataset.index)
    return this.inputContainerTarget.querySelector(`input[data-index="${currentIndex - 1}"]`)
  }

  updateHiddenInput() {
    const inputs = this.inputContainerTarget.querySelectorAll("input")
    const code = Array.from(inputs).map(i => i.value).join("")
    this.hiddenInputTarget.value = code

    // Enable/disable submit button based on code length
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = code.length !== 4
    }
  }

  focusFirstInput() {
    const firstInput = this.inputContainerTarget.querySelector('input[data-index="0"]')
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
  }

  // Expiration timer
  startExpirationTimer() {
    this.expirationSeconds = this.timeRemainingValue
    this.updateCountdown()

    this.expirationInterval = setInterval(() => {
      this.expirationSeconds--
      this.updateCountdown()

      if (this.expirationSeconds <= 0) {
        this.handleExpiration()
      }
    }, 1000)
  }

  updateCountdown() {
    if (!this.hasCountdownTarget) return

    const minutes = Math.floor(this.expirationSeconds / 60)
    const seconds = this.expirationSeconds % 60
    this.countdownTarget.textContent = `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`

    // Change color when low
    if (this.expirationSeconds < 60) {
      this.countdownTarget.classList.remove("text-[#125282]")
      this.countdownTarget.classList.add("text-red-600")
    }
  }

  handleExpiration() {
    this.stopTimers()

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = true
    }

    if (this.hasTimerTarget) {
      this.timerTarget.innerHTML = '<span class="text-red-600 font-semibold">El codigo ha expirado. Por favor solicita uno nuevo.</span>'
    }
  }

  // Resend cooldown timer
  startResendTimer() {
    this.resendSeconds = this.resendCooldownValue

    if (this.resendSeconds <= 0) {
      this.enableResendButton()
      return
    }

    this.updateResendCountdown()

    this.resendInterval = setInterval(() => {
      this.resendSeconds--
      this.updateResendCountdown()

      if (this.resendSeconds <= 0) {
        this.enableResendButton()
      }
    }, 1000)
  }

  updateResendCountdown() {
    if (this.hasResendCountdownTarget) {
      this.resendCountdownTarget.textContent = this.resendSeconds
    }
  }

  enableResendButton() {
    if (this.hasResendBtnTarget) {
      this.resendBtnTarget.disabled = false
    }
    if (this.hasResendTimerTarget) {
      this.resendTimerTarget.classList.add("hidden")
    }
    if (this.resendInterval) {
      clearInterval(this.resendInterval)
    }
  }

  stopTimers() {
    if (this.expirationInterval) {
      clearInterval(this.expirationInterval)
    }
    if (this.resendInterval) {
      clearInterval(this.resendInterval)
    }
  }
}
