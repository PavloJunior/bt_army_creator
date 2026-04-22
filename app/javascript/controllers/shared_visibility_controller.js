import { Controller } from "@hotwired/stimulus"

// Hides owner-only controls (delete button, skill selector) on shared
// army list items that were not added by the current participant.
//
// The server renders every item's owner-only controls and tags them with
// `data-shared-visibility-target="ownerOnly"`. Each item's outer element
// carries `data-added-by-participant-id="<id>"` (empty string for unclaimed).
// This controller reads the current participant id from the
// `currentParticipantId` value and toggles [hidden] accordingly.
//
// The "admin" sentinel keeps every control visible for signed-in admins.
export default class extends Controller {
  static values = { currentParticipantId: String }

  connect() {
    this.apply()
    this.boundApply = this.apply.bind(this)
    document.addEventListener("turbo:before-stream-render", this.boundApply)
    document.addEventListener("turbo:render", this.boundApply)
  }

  disconnect() {
    if (this.boundApply) {
      document.removeEventListener("turbo:before-stream-render", this.boundApply)
      document.removeEventListener("turbo:render", this.boundApply)
    }
  }

  apply() {
    const viewerId = this.currentParticipantIdValue
    const isAdmin = viewerId === "admin"

    // Spectators (no participant id, not admin) must never see owner-only
    // controls — including controls on unclaimed items. Requiring viewerId
    // to be non-empty closes the "empty === empty" match that would otherwise
    // reveal controls on unclaimed items to non-participants after a broadcast.
    this.element.querySelectorAll("[data-added-by-participant-id]").forEach((item) => {
      const ownerId = item.dataset.addedByParticipantId
      const canEdit = isAdmin || (viewerId !== "" && (ownerId === "" || ownerId === viewerId))

      item.querySelectorAll('[data-shared-visibility-target="ownerOnly"]').forEach((el) => {
        if (canEdit) {
          el.removeAttribute("hidden")
        } else {
          el.setAttribute("hidden", "")
        }
      })
    })
  }
}
