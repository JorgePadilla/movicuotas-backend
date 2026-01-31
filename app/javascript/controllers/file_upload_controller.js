import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName", "area", "placeholder", "preview"]
  static values = {
    required: { type: Boolean, default: false }
  }

  connect() {
    // Add pointer cursor to the clickable area
    if (this.hasAreaTarget) {
      this.areaTarget.style.cursor = 'pointer'
    }

    // If there's already a file selected, show its name
    this.updateFileName()
  }

  // Trigger file input when custom button/area is clicked
  openFilePicker() {
    this.inputTarget.click()
  }

  // Update displayed file name when a file is selected
  updateFileName() {
    const file = this.inputTarget.files[0]
    if (file) {
      const fileName = file.name
      const fileSize = this.formatFileSize(file.size)

      if (this.hasFileNameTarget) {
        this.fileNameTarget.textContent = `${fileName} (${fileSize})`
        this.fileNameTarget.classList.remove('hidden')
      }

      // Toggle placeholder/preview if targets exist
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add('hidden')
      if (this.hasPreviewTarget) this.previewTarget.classList.remove('hidden')

      // Add visual feedback that file is selected
      if (this.hasAreaTarget) {
        this.areaTarget.classList.add('border-green-500', 'bg-green-50')
        this.areaTarget.classList.remove('border-gray-300', 'hover:border-[#125282]')
      }
    } else {
      if (this.hasFileNameTarget) {
        this.fileNameTarget.textContent = ''
        this.fileNameTarget.classList.add('hidden')
      }

      // Toggle placeholder/preview if targets exist
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove('hidden')
      if (this.hasPreviewTarget) this.previewTarget.classList.add('hidden')

      // Reset visual feedback
      if (this.hasAreaTarget) {
        this.areaTarget.classList.remove('border-green-500', 'bg-green-50')
        this.areaTarget.classList.add('border-gray-300', 'hover:border-[#125282]')
      }
    }
  }

  // Handle file selection
  handleFileSelect(event) {
    this.updateFileName()
  }

  // Handle drag over (required for drop to work)
  handleDragOver(event) {
    event.preventDefault()
    if (this.hasAreaTarget) {
      this.areaTarget.classList.add('border-[#125282]', 'bg-blue-50')
    }
  }

  // Handle file drop
  handleDrop(event) {
    event.preventDefault()
    if (this.hasAreaTarget) {
      this.areaTarget.classList.remove('border-[#125282]', 'bg-blue-50')
    }
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.updateFileName()
    }
  }

  // Format file size for display
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  // Clear the selected file
  clearFile() {
    this.inputTarget.value = ''
    this.updateFileName()
  }
}