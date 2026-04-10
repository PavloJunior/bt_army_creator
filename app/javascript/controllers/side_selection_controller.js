import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sideRadio", "techBaseCard", "techBaseRadio", "techBasePanel"]

  connect() {
    // Grey out all tech bases until a side is picked
    const selectedRadio = this.sideRadioTargets.find(r => r.checked)
    if (!selectedRadio) {
      this.updateTechBases([])
    } else {
      const availableBases = JSON.parse(selectedRadio.dataset.availableTechBases || "[]")
      this.updateTechBases(availableBases)
    }
  }

  sideChanged() {
    const selectedRadio = this.sideRadioTargets.find(r => r.checked)
    if (!selectedRadio) return

    const availableBases = JSON.parse(selectedRadio.dataset.availableTechBases || "[]")
    this.updateTechBases(availableBases)
  }

  updateTechBases(availableBases) {
    this.techBaseCardTargets.forEach(card => {
      const techBase = card.dataset.techBase
      const radio = card.querySelector("input[type='radio']")
      const panel = card.querySelector("[data-side-selection-target='techBasePanel']")
      const isAvailable = availableBases.includes(techBase)

      // Remove any existing badge
      const existingBadge = panel.querySelector("[data-unavailable-badge]")
      if (existingBadge) existingBadge.remove()

      if (isAvailable) {
        // Restore available state
        card.classList.remove("pointer-events-none")
        card.classList.add("cursor-pointer")
        panel.classList.remove("opacity-35", "border-gray-700/30", "bg-gray-900/30")
        panel.classList.add("border-hud-border", "bg-hud-bg")
        radio.disabled = false
      } else {
        // Disable unavailable tech base
        card.classList.add("pointer-events-none")
        card.classList.remove("cursor-pointer")
        panel.classList.add("opacity-35", "border-gray-700/30", "bg-gray-900/30")
        panel.classList.remove("border-hud-border", "bg-hud-bg")
        radio.disabled = true

        // If this tech base was selected, deselect it
        if (radio.checked) {
          radio.checked = false
        }

        // Add "Niedostępne" badge
        const badge = document.createElement("span")
        badge.setAttribute("data-unavailable-badge", "")
        badge.className = "mt-2 inline-block px-2 py-0.5 text-xs border border-amber-700/40 text-amber-500/60 rounded-full"
        badge.textContent = "Niedostępne"
        panel.appendChild(badge)
      }
    })
  }
}
