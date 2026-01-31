import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName", "area", "placeholder", "preview", "thumbnail"]
  static values = {
    required: { type: Boolean, default: false },
    maxSize: { type: Number, default: 2048 },
    quality: { type: Number, default: 0.7 }
  }

  connect() {
    if (this.hasAreaTarget) {
      this.areaTarget.style.cursor = 'pointer'
    }
  }

  openFilePicker() {
    this.inputTarget.click()
  }

  async handleFileSelect() {
    const file = this.inputTarget.files[0]
    if (!file) {
      this.resetPreview()
      return
    }

    if (file.type.startsWith('image/')) {
      await this.compressAndPreview(file)
    } else {
      this.showFileInfo(file)
    }
  }

  async compressAndPreview(file) {
    this.showProcessing()

    try {
      const compressed = await this.compressImage(file)
      // Replace original file with compressed version
      const dt = new DataTransfer()
      dt.items.add(compressed)
      this.inputTarget.files = dt.files

      this.showImagePreview(compressed)
    } catch {
      // If compression fails, keep original and just show info
      this.showFileInfo(file)
    }
  }

  compressImage(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onerror = reject
      reader.onload = (e) => {
        const img = new Image()
        img.onerror = reject
        img.onload = () => {
          const canvas = document.createElement('canvas')
          const maxSize = this.maxSizeValue
          let width = img.width
          let height = img.height

          if (width > maxSize || height > maxSize) {
            if (width > height) {
              height = Math.round((height * maxSize) / width)
              width = maxSize
            } else {
              width = Math.round((width * maxSize) / height)
              height = maxSize
            }
          }

          canvas.width = width
          canvas.height = height
          const ctx = canvas.getContext('2d')
          ctx.drawImage(img, 0, 0, width, height)

          canvas.toBlob((blob) => {
            if (!blob) { reject(new Error('Compression failed')); return }
            const compressed = new File([blob], file.name.replace(/\.\w+$/, '.jpg'), {
              type: 'image/jpeg',
              lastModified: Date.now()
            })
            resolve(compressed)
          }, 'image/jpeg', this.qualityValue)
        }
        img.src = e.target.result
      }
      reader.readAsDataURL(file)
    })
  }

  showImagePreview(file) {
    const url = URL.createObjectURL(file)

    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
      this.fileNameTarget.classList.remove('hidden')
    }

    if (this.hasThumbnailTarget) {
      this.thumbnailTarget.src = url
      this.thumbnailTarget.classList.remove('hidden')
    }

    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add('hidden')
    if (this.hasPreviewTarget) this.previewTarget.classList.remove('hidden')

    if (this.hasAreaTarget) {
      this.areaTarget.classList.add('border-green-500', 'bg-green-50')
      this.areaTarget.classList.remove('border-gray-300', 'hover:border-[#125282]')
    }
  }

  showFileInfo(file) {
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
      this.fileNameTarget.classList.remove('hidden')
    }

    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add('hidden')
    if (this.hasPreviewTarget) this.previewTarget.classList.remove('hidden')

    if (this.hasAreaTarget) {
      this.areaTarget.classList.add('border-green-500', 'bg-green-50')
      this.areaTarget.classList.remove('border-gray-300', 'hover:border-[#125282]')
    }
  }

  showProcessing() {
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = 'Procesando imagen...'
      this.fileNameTarget.classList.remove('hidden')
    }
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add('hidden')
    if (this.hasPreviewTarget) this.previewTarget.classList.remove('hidden')
  }

  resetPreview() {
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = ''
      this.fileNameTarget.classList.add('hidden')
    }
    if (this.hasThumbnailTarget) {
      this.thumbnailTarget.src = ''
      this.thumbnailTarget.classList.add('hidden')
    }
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove('hidden')
    if (this.hasPreviewTarget) this.previewTarget.classList.add('hidden')

    if (this.hasAreaTarget) {
      this.areaTarget.classList.remove('border-green-500', 'bg-green-50')
      this.areaTarget.classList.add('border-gray-300', 'hover:border-[#125282]')
    }
  }

  handleDragOver(event) {
    event.preventDefault()
    if (this.hasAreaTarget) {
      this.areaTarget.classList.add('border-[#125282]', 'bg-blue-50')
    }
  }

  async handleDrop(event) {
    event.preventDefault()
    if (this.hasAreaTarget) {
      this.areaTarget.classList.remove('border-[#125282]', 'bg-blue-50')
    }
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      await this.handleFileSelect()
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  clearFile() {
    this.inputTarget.value = ''
    this.resetPreview()
  }
}
