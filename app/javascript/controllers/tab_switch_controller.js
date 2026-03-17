import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    default: { type: String, default: "browser" },
    key: { type: String, default: "army-builder-tab" }
  }

  connect() {
    const urlTab = new URLSearchParams(window.location.search).get("tab")
    const saved = sessionStorage.getItem(this.keyValue)
    this.showTab(urlTab || saved || this.defaultValue)
  }

  switch(event) {
    event.preventDefault()
    const name = event.currentTarget.dataset.tabSwitchNameParam
    sessionStorage.setItem(this.keyValue, name)
    this.showTab(name)
  }

  showTab(name) {
    this.tabTargets.forEach(tab => {
      tab.classList.toggle("active", tab.dataset.tabSwitchNameParam === name)
    })
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tabName !== name)
    })
  }
}
