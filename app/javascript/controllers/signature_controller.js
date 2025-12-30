import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "data", "status"]

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext('2d')
    this.isDrawing = false
    this.lastX = 0
    this.lastY = 0
    this.history = []
    this.currentPath = []

    // Set up canvas styling
    this.ctx.lineWidth = 2
    this.ctx.lineCap = 'round'
    this.ctx.lineJoin = 'round'
    this.ctx.strokeStyle = '#125282' // Corporate blue

    // Clear canvas initially
    this.clear()

    // Set up event listeners for touch devices
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Prevent scrolling when drawing on touch devices
    this.canvas.addEventListener('touchstart', (e) => {
      if (e.target === this.canvas) {
        e.preventDefault()
      }
    }, { passive: false })

    this.canvas.addEventListener('touchmove', (e) => {
      if (e.target === this.canvas) {
        e.preventDefault()
      }
    }, { passive: false })
  }

  startDrawing(event) {
    this.isDrawing = true
    const coords = this.getCoordinates(event)
    this.lastX = coords.x
    this.lastY = coords.y
    this.currentPath = [{ x: this.lastX, y: this.lastY }]
  }

  draw(event) {
    if (!this.isDrawing) return

    event.preventDefault()
    const coords = this.getCoordinates(event)

    this.ctx.beginPath()
    this.ctx.moveTo(this.lastX, this.lastY)
    this.ctx.lineTo(coords.x, coords.y)
    this.ctx.stroke()

    this.currentPath.push({ x: coords.x, y: coords.y })
    this.lastX = coords.x
    this.lastY = coords.y
  }

  stopDrawing() {
    if (!this.isDrawing) return

    this.isDrawing = false
    if (this.currentPath.length > 0) {
      this.history.push(this.currentPath)
    }
  }

  clear() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    this.ctx.fillStyle = '#ffffff'
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)
    this.history = []
    this.currentPath = []
    this.showStatus('Canvas limpiado', 'info')
  }

  undo() {
    if (this.history.length === 0) {
      this.showStatus('No hay más acciones para deshacer', 'warning')
      return
    }

    // Clear canvas and redraw all paths except last
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    this.ctx.fillStyle = '#ffffff'
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    this.history.pop()

    // Redraw remaining history
    this.redrawHistory()

    this.showStatus('Última acción deshecha', 'info')
  }

  redrawHistory() {
    this.ctx.beginPath()
    this.history.forEach(path => {
      if (path.length === 0) return

      this.ctx.moveTo(path[0].x, path[0].y)
      for (let i = 1; i < path.length; i++) {
        this.ctx.lineTo(path[i].x, path[i].y)
      }
    })
    this.ctx.stroke()
  }

  save() {
    if (this.history.length === 0) {
      this.showStatus('Por favor, firme en el canvas antes de guardar', 'error')
      return
    }

    // Convert canvas to data URL
    const dataURL = this.canvas.toDataURL('image/png')
    this.dataTarget.value = dataURL

    // Submit the form
    const form = document.getElementById('signatureForm')
    if (form) {
      this.showStatus('Guardando firma...', 'info')
      form.submit()
    }
  }

  getCoordinates(event) {
    let clientX, clientY

    if (event.type.includes('touch')) {
      clientX = event.touches[0].clientX
      clientY = event.touches[0].clientY
    } else {
      clientX = event.clientX
      clientY = event.clientY
    }

    const rect = this.canvas.getBoundingClientRect()
    const scaleX = this.canvas.width / rect.width
    const scaleY = this.canvas.height / rect.height

    return {
      x: (clientX - rect.left) * scaleX,
      y: (clientY - rect.top) * scaleY
    }
  }

  showStatus(message, type) {
    const statusEl = this.statusTarget
    if (!statusEl) return

    const colors = {
      info: 'bg-blue-100 text-blue-800 border-blue-200',
      success: 'bg-green-100 text-green-800 border-green-200',
      error: 'bg-red-100 text-red-800 border-red-200',
      warning: 'bg-yellow-100 text-yellow-800 border-yellow-200'
    }

    statusEl.className = `${colors[type] || colors.info} p-4 rounded-lg border mb-4`
    statusEl.textContent = message
    statusEl.classList.remove('hidden')

    // Auto-hide after 5 seconds
    setTimeout(() => {
      statusEl.classList.add('hidden')
    }, 5000)
  }

  // Handle window resize (maintain signature)
  handleResize() {
    // Store current signature data
    const dataURL = this.canvas.toDataURL('image/png')
    const img = new Image()
    img.onload = () => {
      // Redraw on new canvas size
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
      this.ctx.fillStyle = '#ffffff'
      this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)
      this.ctx.drawImage(img, 0, 0, this.canvas.width, this.canvas.height)
    }
    img.src = dataURL
  }
}