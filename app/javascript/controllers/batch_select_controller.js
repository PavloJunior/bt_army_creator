import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "actions", "sharedField", "count"]

  toggle() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length
    this.actionsTarget.classList.toggle("hidden", checkedCount === 0)
    this.countTarget.textContent = checkedCount
  }

  submitShared() {
    this.sharedFieldTarget.value = "true"
  }

  submitNormal() {
    this.sharedFieldTarget.value = ""
  }

  selectAll() {
    this.checkboxTargets.forEach(cb => { cb.checked = true })
    this.toggle()
  }

  deselectAll() {
    this.checkboxTargets.forEach(cb => { cb.checked = false })
    this.toggle()
  }
}
