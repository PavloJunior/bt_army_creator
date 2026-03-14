import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { default: { type: String, default: "army" } }

  connect() {
    this.showTab(this.defaultValue)
  }

  switch(event) {
    event.preventDefault()
    this.showTab(event.currentTarget.dataset.tabSwitchNameParam)
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
