import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loanSelect", "installmentsContainer"]

  loadInstallments() {
    const loanId = this.loanSelectTarget.value
    const container = this.installmentsContainerTarget

    if (!loanId) {
      container.innerHTML = ""
      return
    }

    container.innerHTML = '<div class="text-center py-4"><div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-[#125282]"></div><p class="mt-2 text-sm text-gray-500">Cargando cuotas...</p></div>'

    fetch(`/admin/payments/loan_installments?loan_id=${loanId}`, {
      headers: {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then(response => response.text())
      .then(html => { container.innerHTML = html })
      .catch(() => { container.innerHTML = '<p class="text-sm text-red-500 py-2">Error al cargar cuotas</p>' })
  }
}
