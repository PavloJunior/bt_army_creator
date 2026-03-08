import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.attempts = 0
    this.maxAttempts = 10
    this.poll()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  poll() {
    if (this.attempts >= this.maxAttempts) {
      this.element.innerHTML = '<p class="text-sm text-gray-400">Nie udało się pobrać karty.</p>'
      return
    }

    this.attempts++
    const delay = this.attempts === 1 ? 2000 : 5000

    this.timeout = setTimeout(() => {
      fetch(this.urlValue)
        .then(response => {
          if (response.ok) {
            window.Turbo.visit(window.location.href, { action: "replace" })
          } else {
            this.poll()
          }
        })
        .catch(() => this.poll())
    }, delay)
  }
}
