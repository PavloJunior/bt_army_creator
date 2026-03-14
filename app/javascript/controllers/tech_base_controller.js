import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  static values = { original: String }

  change() {
    const newValue = this.selectTarget.value
    if (newValue === this.originalValue) return

    this.showConfirm()
  }

  showConfirm() {
    const backdrop = document.createElement("div")
    Object.assign(backdrop.style, {
      position: "fixed",
      top: "0",
      left: "0",
      width: "100vw",
      height: "100vh",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: "rgba(0, 0, 0, 0.75)",
      backdropFilter: "blur(2px)",
      zIndex: "10000"
    })

    backdrop.innerHTML = `
      <div class="hud-panel bg-hud-bg-panel border border-hud-border-bright rounded p-6 mx-4 shadow-lg"
           style="width: 360px; max-width: calc(100vw - 2rem);"
           style="box-shadow: 0 0 30px rgba(0, 255, 65, 0.1), inset 0 0 30px rgba(0, 255, 65, 0.03);">
        <div class="flex items-center gap-2 mb-3">
          <span class="text-hud-amber text-lg">⚠</span>
          <span class="font-hud-heading text-hud-amber font-bold uppercase tracking-wider">Uwaga</span>
        </div>
        <p class="text-hud-text-dim text-sm leading-relaxed mb-5">
          Zmiana frakcji <span class="text-hud-amber">usunie wszystkie jednostki</span> z listy. Kontynuować?
        </p>
        <div class="flex gap-3 justify-end">
          <button data-action="cancel" class="hud-btn-danger px-4 py-2 rounded text-xs cursor-pointer">
            Anuluj
          </button>
          <button data-action="confirm" class="hud-btn-primary px-4 py-2 rounded text-xs cursor-pointer">
            Potwierdź
          </button>
        </div>
      </div>
    `

    backdrop.addEventListener("click", (e) => {
      if (e.target === backdrop || e.target.dataset.action === "cancel") {
        this.dismiss(backdrop)
      }
      if (e.target.dataset.action === "confirm") {
        backdrop.remove()
        this.element.requestSubmit()
      }
    })

    backdrop.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.dismiss(backdrop)
      if (e.key === "Enter") {
        backdrop.remove()
        this.element.requestSubmit()
      }
    })

    document.body.appendChild(backdrop)
    backdrop.querySelector('[data-action="confirm"]').focus()
  }

  dismiss(backdrop) {
    backdrop.remove()
    this.selectTarget.value = this.originalValue
  }
}
