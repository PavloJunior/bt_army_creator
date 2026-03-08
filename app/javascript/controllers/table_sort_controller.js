import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header"]

  sort(event) {
    const th = event.currentTarget
    const colIndex = th.dataset.sortCol
    const type = th.dataset.sortType || "string"

    // Toggle direction
    const wasAsc = th.dataset.sortDir === "asc"
    const dir = wasAsc ? "desc" : "asc"

    // Reset all headers
    this.headerTargets.forEach(h => {
      h.dataset.sortDir = ""
      h.querySelector(".sort-arrow")?.remove()
    })

    // Set active
    th.dataset.sortDir = dir
    const arrow = document.createElement("span")
    arrow.className = "sort-arrow ml-1"
    arrow.textContent = dir === "asc" ? "\u25B2" : "\u25BC"
    th.appendChild(arrow)

    // Collect sortable tbody elements
    const table = this.element
    const bodies = Array.from(table.querySelectorAll("tbody[data-controller='variant-expand']"))

    bodies.sort((a, b) => {
      const cellA = a.querySelector(`tr:first-child td:nth-child(${parseInt(colIndex) + 1})`)
      const cellB = b.querySelector(`tr:first-child td:nth-child(${parseInt(colIndex) + 1})`)
      const valA = cellA?.dataset.sortValue ?? cellA?.textContent?.trim() ?? ""
      const valB = cellB?.dataset.sortValue ?? cellB?.textContent?.trim() ?? ""

      let cmp
      if (type === "number") {
        cmp = (parseFloat(valA) || 0) - (parseFloat(valB) || 0)
      } else {
        cmp = valA.localeCompare(valB, undefined, { numeric: true })
      }

      return dir === "asc" ? cmp : -cmp
    })

    // Re-append in sorted order
    const parent = bodies[0]?.parentNode
    if (parent) {
      bodies.forEach(tb => parent.appendChild(tb))
    }
  }
}
