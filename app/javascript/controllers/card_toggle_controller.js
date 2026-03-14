import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    if (sessionStorage.getItem(this.keyValue) === "open") {
      this.element.open = true
    }
  }

  toggle() {
    sessionStorage.setItem(this.keyValue, this.element.open ? "open" : "closed")
  }
}
