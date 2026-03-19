import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "item",
    "sortSelect",
    "maxPvInput",
    "autoCheckbox",
    "roleSelect",
    "abilitiesInput",
    "panel",
    "toggleButton",
    "badge",
    "emptyState"
  ]

  static values = {
    pointCap: Number,
    armyListId: Number
  }

  connect() {
    this.populateRoles()
    this.restoreState()
    this.observePointTotal()
    this.sort()
  }

  disconnect() {
    if (this.pointTotalObserver) {
      this.pointTotalObserver.disconnect()
    }
  }

  // --- SessionStorage helpers (scoped by army list ID) ---

  get storagePrefix() {
    return `army-builder-${this.armyListIdValue}`
  }

  storeGet(key) {
    return sessionStorage.getItem(`${this.storagePrefix}-${key}`)
  }

  storeSet(key, value) {
    sessionStorage.setItem(`${this.storagePrefix}-${key}`, value)
  }

  storeRemove(key) {
    sessionStorage.removeItem(`${this.storagePrefix}-${key}`)
  }

  // --- Initialization ---

  populateRoles() {
    const roles = new Set()
    this.itemTargets.forEach(item => {
      const variants = this.getVariants(item)
      Object.values(variants).forEach(v => {
        if (v.role) roles.add(v.role)
      })
    })

    const select = this.roleSelectTarget
    while (select.options.length > 1) select.remove(1)

    Array.from(roles).sort().forEach(role => {
      const opt = document.createElement("option")
      opt.value = role
      opt.textContent = role
      select.appendChild(opt)
    })
  }

  restoreState() {
    const sort = this.storeGet("sort")
    if (sort) this.sortSelectTarget.value = sort

    const maxPv = this.storeGet("max-pv")
    if (maxPv !== null && maxPv !== "") this.maxPvInputTarget.value = maxPv

    const auto = this.storeGet("auto-pv")
    this.autoCheckboxTarget.checked = auto === "true"
    if (this.autoCheckboxTarget.checked) {
      this.maxPvInputTarget.readOnly = true
      this.computeAutoBudget()
    }

    const role = this.storeGet("role")
    if (role) this.roleSelectTarget.value = role

    const abilities = this.storeGet("abilities")
    if (abilities) this.abilitiesInputTarget.value = abilities

    const panel = this.storeGet("filter-panel")
    if (panel !== "closed") {
      this.panelTarget.classList.remove("hidden")
      this.toggleButtonTarget.classList.add("active")
    }
  }

  observePointTotal() {
    const el = document.getElementById("point_total")
    if (!el) return

    this.pointTotalObserver = new MutationObserver(() => {
      if (this.autoCheckboxTarget.checked) {
        this.computeAutoBudget()
        this.filter()
      }
    })
    this.pointTotalObserver.observe(el, { childList: true, subtree: true, characterData: true })
  }

  computeAutoBudget() {
    const el = document.getElementById("point_total")
    if (!el) return

    const text = el.textContent
    const match = text.match(/(\d+)\s*\/\s*(\d+)/)
    if (!match) return

    const currentTotal = parseInt(match[1], 10)
    const cap = parseInt(match[2], 10)
    const remaining = Math.max(0, cap - currentTotal)

    this.maxPvInputTarget.value = remaining
    this.storeSet("max-pv", remaining.toString())
  }

  // --- Data helpers ---

  getVariants(item) {
    const el = item.querySelector("[data-variant-preview-variants-value]")
    if (!el) return {}
    try {
      return JSON.parse(el.dataset.variantPreviewVariantsValue)
    } catch { return {} }
  }

  // --- Actions ---

  sort() {
    const value = this.sortSelectTarget.value
    this.storeSet("sort", value)

    const [field, direction] = value.split("-")
    const container = document.getElementById("available_miniatures")
    if (!container) return

    const items = Array.from(this.itemTargets)

    items.sort((a, b) => {
      let aVal, bVal
      if (field === "name") {
        aVal = (a.dataset.chassisName || "").toLowerCase()
        bVal = (b.dataset.chassisName || "").toLowerCase()
        return direction === "asc"
          ? aVal.localeCompare(bVal)
          : bVal.localeCompare(aVal)
      } else {
        aVal = parseInt(a.dataset.chassisTonnage, 10) || 0
        bVal = parseInt(b.dataset.chassisTonnage, 10) || 0
        const diff = direction === "asc" ? aVal - bVal : bVal - aVal
        if (diff === 0) {
          const aName = (a.dataset.chassisName || "").toLowerCase()
          const bName = (b.dataset.chassisName || "").toLowerCase()
          return aName.localeCompare(bName)
        }
        return diff
      }
    })

    const fragment = document.createDocumentFragment()
    items.forEach(item => fragment.appendChild(item))
    container.appendChild(fragment)

    this.filter()
  }

  filter() {
    this.storeSet("max-pv", this.maxPvInputTarget.value)
    this.storeSet("role", this.roleSelectTarget.value)
    this.storeSet("abilities", this.abilitiesInputTarget.value)

    const maxPv = this.maxPvInputTarget.value !== ""
      ? parseInt(this.maxPvInputTarget.value, 10) : null
    const role = this.roleSelectTarget.value
    const abilitiesText = this.abilitiesInputTarget.value.trim()
    const abilityCodes = abilitiesText
      ? abilitiesText.split(",").map(s => s.trim().toUpperCase()).filter(Boolean)
      : []

    let visibleCount = 0

    this.itemTargets.forEach(item => {
      const variants = this.getVariants(item)
      const variantList = Object.values(variants)

      const matchingVariants = variantList.filter(v => {
        if (maxPv !== null && (v.pv || 0) > maxPv) return false
        if (role !== "all" && v.role !== role) return false
        if (abilityCodes.length > 0) {
          const abilities = (v.bf_abilities || "").toUpperCase()
          if (!abilityCodes.every(code => abilities.includes(code))) return false
        }
        return true
      })

      const hasFilters = maxPv !== null || role !== "all" || abilityCodes.length > 0
      const hidden = hasFilters && matchingVariants.length === 0 && variantList.length > 0
      item.classList.toggle("hidden-by-filter", hidden)
      if (!hidden) visibleCount++

      this.filterVariantDropdowns(item, matchingVariants, hasFilters)
    })

    this.updateBadge()
    this.updateEmptyState(visibleCount)
  }

  filterVariantDropdowns(item, matchingVariants, hasFilters) {
    if (!hasFilters) {
      this.restoreOriginalDropdowns(item)
      return
    }

    const matchingIds = new Set(matchingVariants.map(v => String(v.id)))
    const sortValue = this.sortSelectTarget.value
    const sorted = this.sortVariants(matchingVariants, sortValue)

    const selects = item.querySelectorAll('[data-variant-preview-target="select"]')
    selects.forEach(select => {
      this.backupOriginalOptions(select)
      const currentValue = select.value
      const isCardView = !!select.closest('[data-view-toggle-target="gridItem"]')

      // Remove all non-prompt options
      Array.from(select.options).forEach(opt => {
        if (opt.value !== "") select.removeChild(opt)
      })

      // Re-add matching options in sorted order
      sorted.forEach(v => {
        const opt = document.createElement("option")
        opt.value = String(v.id)
        opt.textContent = isCardView
          ? `${v.name} (${v.pv} ${v.pv_label})`
          : `${v.name} (${v.pv})`
        select.appendChild(opt)
      })

      // Restore selection if still valid
      if (matchingIds.has(currentValue)) {
        select.value = currentValue
      } else {
        select.value = ""
      }
    })
  }

  backupOriginalOptions(select) {
    if (select._originalOptions) return
    select._originalOptions = Array.from(select.options).map(opt => ({
      value: opt.value,
      text: opt.textContent
    }))
  }

  restoreOriginalDropdowns(item) {
    const selects = item.querySelectorAll('[data-variant-preview-target="select"]')
    selects.forEach(select => {
      if (!select._originalOptions) return
      const currentValue = select.value

      while (select.options.length > 0) select.remove(0)
      select._originalOptions.forEach(({ value, text }) => {
        const opt = document.createElement("option")
        opt.value = value
        opt.textContent = text
        select.appendChild(opt)
      })

      select.value = currentValue
      delete select._originalOptions
    })
  }

  sortVariants(variants, sortValue) {
    return [...variants].sort((a, b) => {
      if (sortValue.startsWith("name")) {
        const cmp = (a.name || "").localeCompare(b.name || "")
        return sortValue === "name-desc" ? -cmp : cmp
      } else {
        const diff = (a.pv || 0) - (b.pv || 0)
        return sortValue === "tonnage-desc" ? -diff : diff
      }
    })
  }

  toggleAuto() {
    const checked = this.autoCheckboxTarget.checked
    this.storeSet("auto-pv", checked.toString())

    if (checked) {
      this.maxPvInputTarget.readOnly = true
      this.computeAutoBudget()
    } else {
      this.maxPvInputTarget.readOnly = false
    }
    this.filter()
  }

  togglePanel() {
    const isHidden = this.panelTarget.classList.toggle("hidden")
    this.toggleButtonTarget.classList.toggle("active", !isHidden)
    this.storeSet("filter-panel", isHidden ? "closed" : "open")
  }

  clearFilters() {
    this.sortSelectTarget.value = "name-asc"
    this.maxPvInputTarget.value = ""
    this.maxPvInputTarget.readOnly = false
    this.autoCheckboxTarget.checked = false
    this.roleSelectTarget.value = "all"
    this.abilitiesInputTarget.value = ""

    this.storeRemove("sort")
    this.storeRemove("max-pv")
    this.storeRemove("auto-pv")
    this.storeRemove("role")
    this.storeRemove("abilities")

    this.sort()
  }

  updateBadge() {
    let count = 0
    if (this.sortSelectTarget.value !== "name-asc") count++
    if (this.maxPvInputTarget.value !== "") count++
    if (this.roleSelectTarget.value !== "all") count++
    if (this.abilitiesInputTarget.value.trim() !== "") count++

    if (count > 0) {
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.remove("hidden")
    } else {
      this.badgeTarget.classList.add("hidden")
    }
  }

  updateEmptyState(visibleCount) {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }

  // --- Turbo Stream compatibility ---

  itemTargetConnected(el) {
    this.populateRoles()

    const variants = this.getVariants(el)
    const variantList = Object.values(variants)

    const maxPv = this.maxPvInputTarget.value !== ""
      ? parseInt(this.maxPvInputTarget.value, 10) : null
    const role = this.roleSelectTarget.value
    const abilitiesText = this.abilitiesInputTarget.value.trim()
    const abilityCodes = abilitiesText
      ? abilitiesText.split(",").map(s => s.trim().toUpperCase()).filter(Boolean)
      : []

    const matchingVariants = variantList.filter(v => {
      if (maxPv !== null && (v.pv || 0) > maxPv) return false
      if (role !== "all" && v.role !== role) return false
      if (abilityCodes.length > 0) {
        const abilities = (v.bf_abilities || "").toUpperCase()
        if (!abilityCodes.every(code => abilities.includes(code))) return false
      }
      return true
    })

    const hasFilters = maxPv !== null || role !== "all" || abilityCodes.length > 0
    const hidden = hasFilters && matchingVariants.length === 0 && variantList.length > 0
    el.classList.toggle("hidden-by-filter", hidden)

    this.filterVariantDropdowns(el, matchingVariants, hasFilters)
  }
}
