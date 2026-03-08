import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details", "arrow"]

  toggle({ params: { id } }) {
    const details = id
      ? this.detailsTargets.find(el => el.dataset.id === String(id))
      : this.detailsTarget
    const arrow = id
      ? this.arrowTargets.find(el => el.dataset.id === String(id))
      : this.arrowTarget
    if (!details || !arrow) return

    if (details.classList.contains("hidden")) {
      details.classList.remove("hidden")
      arrow.innerHTML = "&#9660;"
    } else {
      details.classList.add("hidden")
      arrow.innerHTML = "&#9654;"
    }
  }
}
