import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.specials = this.loadSpecials()
  }

  loadSpecials() {
    const el = document.getElementById("specials-data")
    if (!el) return {}
    try { return JSON.parse(el.dataset.specials) } catch { return {} }
  }

  show(event) {
    const btn = event.currentTarget
    const abbr = btn.dataset.specialAbbreviation
    const token = btn.dataset.specialToken
    const special = this.specials[abbr]
    if (!special) return

    this.showModal(token, special.name, special.desc)
  }

  esc(value) {
    if (value == null) return ""
    const div = document.createElement("div")
    div.textContent = String(value)
    return div.innerHTML
  }

  showModal(token, fullName, description) {
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
      <div class="hud-panel bg-hud-bg-panel border border-hud-border-bright rounded p-6 mx-4"
           style="width: 480px; max-width: calc(100vw - 2rem); max-height: calc(100vh - 4rem); overflow-y: auto;
                  box-shadow: 0 0 30px rgba(0, 255, 65, 0.1), inset 0 0 30px rgba(0, 255, 65, 0.03);">
        <div class="flex items-center gap-3 mb-4">
          <span class="font-hud-heading text-hud-green font-bold text-xl uppercase tracking-wider">${this.esc(token)}</span>
          <span class="text-hud-text-muted text-sm">${this.esc(fullName)}</span>
        </div>
        <p class="text-hud-text-dim text-sm leading-relaxed whitespace-pre-line">
          ${this.esc(description)}
        </p>
        <div class="flex justify-end mt-5">
          <button data-role="close" class="hud-btn-primary px-4 py-2 rounded text-xs cursor-pointer">
            Zamknij
          </button>
        </div>
      </div>
    `

    backdrop.addEventListener("click", (e) => {
      if (e.target === backdrop || e.target.closest('[data-role="close"]')) {
        backdrop.remove()
      }
    })

    backdrop.addEventListener("keydown", (e) => {
      if (e.key === "Escape") backdrop.remove()
    })

    document.body.appendChild(backdrop)
    backdrop.querySelector('[data-role="close"]').focus()
  }
}
