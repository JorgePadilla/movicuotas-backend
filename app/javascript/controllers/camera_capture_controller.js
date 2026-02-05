import { Controller } from "@hotwired/stimulus"

// Camera capture controller for taking photos with webcam/mobile camera
export default class extends Controller {
  static targets = ["video", "canvas", "preview", "input", "captureBtn", "retakeBtn", "placeholder", "status", "startBtn"]
  static values = {
    facingMode: { type: String, default: "environment" } // "environment" for back camera, "user" for front/selfie
  }

  connect() {
    this.stream = null
    this.photoTaken = false
  }

  disconnect() {
    this.stopCamera()
  }

  async startCamera() {
    try {
      // Request camera access
      const constraints = {
        video: {
          facingMode: this.facingModeValue,
          width: { ideal: 1280 },
          height: { ideal: 720 }
        },
        audio: false
      }

      this.stream = await navigator.mediaDevices.getUserMedia(constraints)
      this.videoTarget.srcObject = this.stream
      await this.videoTarget.play()

      // Show video, hide placeholder
      this.videoTarget.classList.remove("hidden")
      this.placeholderTarget.classList.add("hidden")
      this.captureBtnTarget.classList.remove("hidden")
      this.retakeBtnTarget.classList.add("hidden")

      // Hide start button
      if (this.hasStartBtnTarget) {
        this.startBtnTarget.classList.add("hidden")
      }

      // Mirror video for front camera (selfie mode)
      if (this.facingModeValue === "user") {
        this.videoTarget.style.transform = "scaleX(-1)"
      } else {
        this.videoTarget.style.transform = "scaleX(1)"
      }

      if (this.hasPreviewTarget) {
        this.previewTarget.classList.add("hidden")
      }

      this.updateStatus("Cámara lista. Presiona 'Capturar' para tomar la foto.", "info")
    } catch (error) {
      console.error("Error accessing camera:", error)
      this.updateStatus("Error al acceder a la cámara. Verifica los permisos.", "error")
    }
  }

  stopCamera() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
    this.videoTarget.srcObject = null
  }

  capture() {
    if (!this.stream) return

    const video = this.videoTarget
    const canvas = this.canvasTarget

    // Set canvas size to match video
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight

    // Draw video frame to canvas
    const context = canvas.getContext("2d")

    // If using front camera (selfie), mirror the image
    if (this.facingModeValue === "user") {
      context.translate(canvas.width, 0)
      context.scale(-1, 1)
    }

    context.drawImage(video, 0, 0, canvas.width, canvas.height)

    // Convert canvas to blob and set to file input
    canvas.toBlob((blob) => {
      if (blob) {
        // Create a File object from the blob
        const fileName = `photo_${Date.now()}.jpg`
        const file = new File([blob], fileName, { type: "image/jpeg" })

        // Create a DataTransfer to set the file input
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)
        this.inputTarget.files = dataTransfer.files
        this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))

        // Show preview
        if (this.hasPreviewTarget) {
          this.previewTarget.src = canvas.toDataURL("image/jpeg")
          this.previewTarget.classList.remove("hidden")
        }

        this.photoTaken = true
        this.updateStatus("Foto capturada correctamente.", "success")
      }
    }, "image/jpeg", 0.9)

    // Stop camera and show retake button
    this.stopCamera()
    this.videoTarget.classList.add("hidden")
    this.captureBtnTarget.classList.add("hidden")
    this.retakeBtnTarget.classList.remove("hidden")
  }

  retake() {
    this.photoTaken = false

    // Clear the file input
    this.inputTarget.value = ""

    // Hide preview
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }

    // Hide retake button, show start button while camera restarts
    this.retakeBtnTarget.classList.add("hidden")

    // Restart camera
    this.startCamera()
  }

  switchCamera() {
    // Toggle between front and back camera
    this.facingModeValue = this.facingModeValue === "environment" ? "user" : "environment"

    if (this.stream) {
      this.stopCamera()
      this.startCamera()
    }
  }

  updateStatus(message, type) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("hidden", "text-green-600", "text-red-600", "text-blue-600")

    switch(type) {
      case "success":
        this.statusTarget.classList.add("text-green-600")
        break
      case "error":
        this.statusTarget.classList.add("text-red-600")
        break
      default:
        this.statusTarget.classList.add("text-blue-600")
    }
  }
}
