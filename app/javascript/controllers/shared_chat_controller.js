import { Controller } from "@hotwired/stimulus"

// Drives the shared army list chat panel: auto-scrolls to the newest message,
// toggles the "no messages" empty state, clears the input on submit, and
// blocks empty messages client-side.
export default class extends Controller {
  static targets = ["messages", "input", "emptyState"]

  connect() {
    this.refresh()
    this.observer = new MutationObserver(() => this.refresh())
    if (this.hasMessagesTarget) {
      this.observer.observe(this.messagesTarget, { childList: true, subtree: false })
    }
  }

  disconnect() {
    this.observer?.disconnect()
  }

  submit(event) {
    if (!this.hasInputTarget) return
    const value = this.inputTarget.value.trim()
    if (value === "") {
      event.preventDefault()
      return
    }
    // The server replaces the form wrapper via Turbo Stream on success, which
    // resets the input. On failure it re-renders with the previous text intact
    // plus an error message — so we must NOT clear optimistically.
  }

  refresh() {
    this.toggleEmptyState()
    this.scrollToBottom()
  }

  toggleEmptyState() {
    if (!this.hasEmptyStateTarget || !this.hasMessagesTarget) return
    const hasMessages = this.messagesTarget.children.length > 0
    this.emptyStateTarget.classList.toggle("hidden", hasMessages)
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
