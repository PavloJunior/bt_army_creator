import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidesEditor", "factionRestrictions", "pointCapField", "sideContainer", "sideTemplate", "addSideButton", "sharedTechBaseField"]

  connect() {
    this.syncVisibility()
  }

  toggle() {
    this.syncVisibility()
  }

  syncVisibility() {
    const themedCheckbox = this.element.querySelector("[data-themed-checkbox]")
    const sharedCheckbox = this.element.querySelector("[data-shared-checkbox]")

    // Mutual exclusion: checking one disables the other.
    if (themedCheckbox && sharedCheckbox) {
      if (themedCheckbox.checked) {
        sharedCheckbox.checked = false
        sharedCheckbox.disabled = true
      } else {
        sharedCheckbox.disabled = false
      }
      if (sharedCheckbox.checked) {
        themedCheckbox.checked = false
        themedCheckbox.disabled = true
      } else {
        themedCheckbox.disabled = false
      }
    }

    const themed = themedCheckbox ? themedCheckbox.checked : false
    const shared = sharedCheckbox ? sharedCheckbox.checked : false

    if (this.hasSidesEditorTarget) {
      this.sidesEditorTarget.classList.toggle("hidden", !themed)
    }
    if (this.hasFactionRestrictionsTarget) {
      this.factionRestrictionsTarget.classList.toggle("hidden", themed)
    }
    if (this.hasPointCapFieldTarget) {
      this.pointCapFieldTarget.classList.toggle("hidden", themed)
      // Remove required from event-level point_cap when themed (caps are per-side)
      const pointCapInput = this.pointCapFieldTarget.querySelector("input[type='number']")
      if (pointCapInput) {
        pointCapInput.required = !themed
      }
    }
    if (this.hasSharedTechBaseFieldTarget) {
      this.sharedTechBaseFieldTarget.classList.toggle("hidden", !shared)
    }

    if (themed) {
      this.enforceMinSides()
    }
  }

  addSide(event) {
    event.preventDefault()
    const sides = this.sideContainerTargets
    if (sides.length >= 4) return

    const template = this.sideTemplateTarget
    const clone = template.content.cloneNode(true)

    // Update position field
    const positionField = clone.querySelector("[data-position-field]")
    if (positionField) {
      positionField.value = sides.length + 1
    }

    // Insert before the add button
    this.addSideButtonTarget.parentNode.insertBefore(clone, this.addSideButtonTarget)

    this.updateSideNumbers()
    this.updateButtonStates()
  }

  removeSide(event) {
    event.preventDefault()
    const sides = this.sideContainerTargets
    if (sides.length <= 2) return

    const sidePanel = event.target.closest("[data-themed-event-target='sideContainer']")
    if (sidePanel) {
      sidePanel.remove()
      this.updateSideNumbers()
      this.updateButtonStates()
    }
  }

  enforceMinSides() {
    // If there are fewer than 2 sides, add from template until we have 2
    while (this.sideContainerTargets.length < 2) {
      const template = this.sideTemplateTarget
      const clone = template.content.cloneNode(true)
      const positionField = clone.querySelector("[data-position-field]")
      if (positionField) {
        positionField.value = this.sideContainerTargets.length + 1
      }
      this.addSideButtonTarget.parentNode.insertBefore(clone, this.addSideButtonTarget)
    }
    this.updateSideNumbers()
    this.updateButtonStates()
  }

  updateSideNumbers() {
    this.sideContainerTargets.forEach((side, index) => {
      const label = side.querySelector("[data-side-number]")
      if (label) label.textContent = `Side ${index + 1}`
      const positionField = side.querySelector("[data-position-field]")
      if (positionField) positionField.value = index + 1
    })
  }

  updateButtonStates() {
    const count = this.sideContainerTargets.length

    // Disable add if at max
    if (this.hasAddSideButtonTarget) {
      this.addSideButtonTarget.disabled = count >= 4
      this.addSideButtonTarget.classList.toggle("opacity-50", count >= 4)
      this.addSideButtonTarget.classList.toggle("cursor-not-allowed", count >= 4)
    }

    // Disable remove if at min
    this.sideContainerTargets.forEach(side => {
      const removeBtn = side.querySelector("[data-remove-side]")
      if (removeBtn) {
        removeBtn.disabled = count <= 2
        removeBtn.classList.toggle("opacity-50", count <= 2)
        removeBtn.classList.toggle("cursor-not-allowed", count <= 2)
      }
    })
  }
}
