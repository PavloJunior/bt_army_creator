import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details", "card", "select", "submit"]
  static values = { variants: Object, gameSystem: String }

  load() {
    const variantId = this.selectTarget.value
    if (!variantId) {
      this.detailsTarget.innerHTML = ""
      if (this.hasCardTarget) {
        const scrollY = window.scrollY
        this.cardTarget.innerHTML = ""
        window.scrollTo(0, scrollY)
      }
      return
    }

    const variant = this.variantsValue[variantId]
    if (!variant) return

    this.detailsTarget.innerHTML = this.buildStatsHtml(variant)

    if (this.hasCardTarget && this.gameSystemValue === "alpha_strike") {
      const currentHeight = this.cardTarget.offsetHeight
      if (currentHeight > 0) {
        this.cardTarget.style.minHeight = `${currentHeight}px`
      }

      const img = document.createElement("img")
      img.src = `/variants/${variant.id}/card?skill=4`
      img.className = "w-full rounded border border-hud-border mt-2"
      img.alt = `Karta ${variant.name}`
      img.addEventListener("load", () => { this.cardTarget.style.minHeight = "" })
      img.addEventListener("error", () => {
        this.cardTarget.style.minHeight = ""
        this.cardTarget.innerHTML = ""
      })
      this.cardTarget.replaceChildren(img)
    }
  }

  esc(value) {
    if (value == null) return null
    const div = document.createElement("div")
    div.textContent = String(value)
    return div.innerHTML
  }

  buildAbilityButtons(abilitiesStr) {
    if (!abilitiesStr) return ""

    const specialsEl = document.getElementById("specials-data")
    if (!specialsEl) return `<span class="text-hud-text-dim">${this.esc(abilitiesStr)}</span>`

    let specials
    try { specials = JSON.parse(specialsEl.dataset.specials) } catch {
      return `<span class="text-hud-text-dim">${this.esc(abilitiesStr)}</span>`
    }

    const abbreviations = Object.keys(specials).sort((a, b) => b.length - a.length)
    const tokens = abilitiesStr.split(/,\s*/)

    return tokens.map(token => {
      const e = this.esc(token)
      const base = abbreviations.find(abbr => {
        if (!token.startsWith(abbr)) return false
        const remainder = token.slice(abbr.length)
        return remainder === "" || /^[^a-zA-Z]/.test(remainder)
      })

      if (base) {
        return `<button type="button"
                  class="inline-block px-1.5 py-0.5 text-xs rounded border border-hud-border text-hud-green-dim hover:text-hud-green hover:border-hud-green-dim cursor-pointer bg-transparent transition-colors"
                  data-action="special-ability-modal#show"
                  data-special-abbreviation="${this.esc(base)}"
                  data-special-token="${e}">${e}</button>`
      }
      return `<span class="inline-block px-1.5 py-0.5 text-xs text-hud-text-dim">${e}</span>`
    }).join(" ")
  }

  buildStatsHtml(v) {
    const e = (val) => this.esc(val)
    const dash = "\u2014"
    const s = (val) => e(val) || dash

    if (this.gameSystemValue === "alpha_strike") {
      return `
        <div class="mt-3 p-3 bg-hud-bg rounded border border-hud-border text-sm">
          <div class="font-semibold text-hud-green mb-2">${s(v.name)} &middot; ${s(v.pv)} ${s(v.pv_label)}</div>
          <div class="grid grid-cols-2 gap-x-6 gap-y-1 text-hud-text-dim">
            <div><span class="text-hud-text-muted">Tonnage:</span> ${s(v.tonnage)}</div>
            <div><span class="text-hud-text-muted">Role:</span> ${s(v.role)}</div>
            <div><span class="text-hud-text-muted">Move:</span> ${s(v.bf_move)}</div>
            <div><span class="text-hud-text-muted">Size:</span> ${s(v.bf_size)}</div>
            <div><span class="text-hud-text-muted">DMG (S/M/L):</span> ${e(v.bf_damage_short) ?? dash}/${e(v.bf_damage_medium) ?? dash}/${e(v.bf_damage_long) ?? dash}</div>
            <div><span class="text-hud-text-muted">Overheat:</span> ${s(v.bf_overheat)}</div>
            <div><span class="text-hud-text-muted">Armor:</span> ${s(v.bf_armor)}</div>
            <div><span class="text-hud-text-muted">Structure:</span> ${s(v.bf_structure)}</div>
          </div>
          ${v.bf_abilities ? `<div class="mt-2 flex flex-wrap items-center gap-1" data-controller="special-ability-modal"><span class="text-hud-text-muted mr-1">Special:</span> ${this.buildAbilityButtons(v.bf_abilities)}</div>` : ""}
          <div class="mt-2 text-xs text-hud-text-muted">
            ${s(v.technology)} &middot; ${s(v.era)}
          </div>
        </div>`
    } else {
      return `
        <div class="mt-3 p-3 bg-hud-bg rounded border border-hud-border text-sm">
          <div class="font-semibold text-hud-green mb-2">${s(v.name)} &middot; ${s(v.pv)} ${s(v.pv_label)}</div>
          <div class="grid grid-cols-2 gap-x-6 gap-y-1 text-hud-text-dim">
            <div><span class="text-hud-text-muted">Tonnage:</span> ${s(v.tonnage)}</div>
            <div><span class="text-hud-text-muted">Role:</span> ${s(v.role)}</div>
            <div><span class="text-hud-text-muted">Era:</span> ${s(v.era)}</div>
            <div><span class="text-hud-text-muted">Technology:</span> ${s(v.technology)}</div>
            <div><span class="text-hud-text-muted">Rules level:</span> ${s(v.rules_level)}</div>
            <div><span class="text-hud-text-muted">Introduced:</span> ${s(v.date_introduced)}</div>
          </div>
        </div>`
    }
  }
}
