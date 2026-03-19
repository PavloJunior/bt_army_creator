import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "item"]
  static values = { key: { type: String, default: "army-builder-unit-type" } }

  connect() {
    this.applyFilter(this.currentFilter)
  }

  filter(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.unitType
    const newFilter = (type === this.currentFilter) ? "all" : type
    this.setFilter(newFilter)
  }

  get currentFilter() {
    return sessionStorage.getItem(this.keyValue) || "all"
  }

  setFilter(type) {
    sessionStorage.setItem(this.keyValue, type)
    this.applyFilter(type)
  }

  applyFilter(type) {
    this.buttonTargets.forEach(btn => {
      btn.classList.toggle("active", btn.dataset.unitType === type)
    })

    this.itemTargets.forEach(el => {
      if (type === "all") {
        el.classList.remove("hidden-by-type")
      } else {
        el.classList.toggle("hidden-by-type", el.dataset.unitType !== type)
      }
    })
  }

  itemTargetConnected(el) {
    const type = this.currentFilter
    if (type !== "all") {
      el.classList.toggle("hidden-by-type", el.dataset.unitType !== type)
    }
  }
}
