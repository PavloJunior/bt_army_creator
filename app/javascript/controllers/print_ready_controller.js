import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    printUrl: String,
    readyText: { type: String, default: "Drukuj karty" },
    pendingText: { type: String, default: "Przygotowywanie kart" }
  }

  connect() {
    this.check()
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  async check() {
    try {
      const response = await fetch(this.urlValue)
      const data = await response.json()

      if (data.ready) {
        this.element.textContent = this.readyTextValue
        this.element.removeAttribute("disabled")
        this.element.style.pointerEvents = ""
        this.element.style.opacity = ""
        this.element.href = this.printUrlValue
      } else {
        this.element.textContent = `${this.pendingTextValue}... (${data.pending})`
        this.element.setAttribute("disabled", "")
        this.element.style.pointerEvents = "none"
        this.element.style.opacity = "0.5"
        this.element.removeAttribute("href")
        this.timeout = setTimeout(() => this.check(), 3000)
      }
    } catch {
      this.timeout = setTimeout(() => this.check(), 5000)
    }
  }
}
