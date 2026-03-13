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
      img.className = "w-full rounded border border-gray-200 mt-2"
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

  buildStatsHtml(v) {
    const e = (val) => this.esc(val)
    const dash = "\u2014"
    const s = (val) => e(val) || dash

    if (this.gameSystemValue === "alpha_strike") {
      return `
        <div class="mt-3 p-3 bg-gray-50 rounded-lg text-sm">
          <div class="font-medium text-gray-900 mb-2">${s(v.name)} &middot; ${s(v.pv)} ${s(v.pv_label)}</div>
          <div class="grid grid-cols-2 gap-x-6 gap-y-1 text-gray-600">
            <div><span class="text-gray-400">Tonnage:</span> ${s(v.tonnage)}</div>
            <div><span class="text-gray-400">Role:</span> ${s(v.role)}</div>
            <div><span class="text-gray-400">Move:</span> ${s(v.bf_move)}</div>
            <div><span class="text-gray-400">Size:</span> ${s(v.bf_size)}</div>
            <div><span class="text-gray-400">DMG (S/M/L):</span> ${e(v.bf_damage_short) ?? dash}/${e(v.bf_damage_medium) ?? dash}/${e(v.bf_damage_long) ?? dash}</div>
            <div><span class="text-gray-400">Overheat:</span> ${s(v.bf_overheat)}</div>
            <div><span class="text-gray-400">Armor:</span> ${s(v.bf_armor)}</div>
            <div><span class="text-gray-400">Structure:</span> ${s(v.bf_structure)}</div>
          </div>
          ${v.bf_abilities ? `<div class="mt-2"><span class="text-gray-400">Special:</span> <span class="text-gray-600">${s(v.bf_abilities)}</span></div>` : ""}
          <div class="mt-2 text-xs text-gray-400">
            ${s(v.technology)} &middot; ${s(v.era)}
          </div>
        </div>`
    } else {
      return `
        <div class="mt-3 p-3 bg-gray-50 rounded-lg text-sm">
          <div class="font-medium text-gray-900 mb-2">${s(v.name)} &middot; ${s(v.pv)} ${s(v.pv_label)}</div>
          <div class="grid grid-cols-2 gap-x-6 gap-y-1 text-gray-600">
            <div><span class="text-gray-400">Tonnage:</span> ${s(v.tonnage)}</div>
            <div><span class="text-gray-400">Role:</span> ${s(v.role)}</div>
            <div><span class="text-gray-400">Era:</span> ${s(v.era)}</div>
            <div><span class="text-gray-400">Technology:</span> ${s(v.technology)}</div>
            <div><span class="text-gray-400">Rules level:</span> ${s(v.rules_level)}</div>
            <div><span class="text-gray-400">Introduced:</span> ${s(v.date_introduced)}</div>
          </div>
        </div>`
    }
  }
}
