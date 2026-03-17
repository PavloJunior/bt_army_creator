import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gridItem", "listItem", "gridButton", "listButton", "container"]
  static values = { key: { type: String, default: "army-builder-view" } }

  connect() {
    this.applyView(this.currentView)
  }

  grid(event) {
    event.preventDefault()
    this.setView("grid")
  }

  list(event) {
    event.preventDefault()
    this.setView("list")
  }

  get currentView() {
    return sessionStorage.getItem(this.keyValue) || "list"
  }

  setView(view) {
    sessionStorage.setItem(this.keyValue, view)
    this.applyView(view)
  }

  applyView(view) {
    const isGrid = view === "grid"

    this.gridItemTargets.forEach(el => el.classList.toggle("hidden", !isGrid))
    this.listItemTargets.forEach(el => el.classList.toggle("hidden", isGrid))

    if (this.hasContainerTarget) {
      const ct = this.containerTarget
      ct.classList.toggle("grid", isGrid)
      ct.classList.toggle("gap-4", isGrid)
      ct.classList.toggle("md:grid-cols-2", isGrid)
      ct.classList.toggle("space-y-2", !isGrid)
    }

    this.gridButtonTargets.forEach(btn => btn.classList.toggle("active", isGrid))
    this.listButtonTargets.forEach(btn => btn.classList.toggle("active", !isGrid))
  }

  gridItemTargetConnected(el) {
    el.classList.toggle("hidden", this.currentView !== "grid")
  }

  listItemTargetConnected(el) {
    el.classList.toggle("hidden", this.currentView !== "list")
  }
}
