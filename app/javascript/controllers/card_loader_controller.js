import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, itemId: String }

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
      this.element.innerHTML = '<p class="text-sm text-hud-text-muted">Nie udało się pobrać karty.</p>'
      return
    }

    this.attempts++
    const delay = this.attempts === 1 ? 2000 : 5000

    this.timeout = setTimeout(() => {
      fetch(this.urlValue)
        .then(response => {
          if (response.ok) {
            const container = document.getElementById(this.itemIdValue)
            if (container) {
              const img = document.createElement("img")
              img.src = response.url
              img.className = "w-full rounded border border-hud-border"
              container.replaceChildren(img)
            }
          } else {
            this.poll()
          }
        })
        .catch(() => this.poll())
    }, delay)
  }
}
