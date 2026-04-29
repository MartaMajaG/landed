import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["board"]
  static values  = { url: String }

  async switchTab(event) {
    const clickedBtn = event.currentTarget
    const tab        = clickedBtn.dataset.tab

    // Swap active class on buttons
    this.element.querySelectorAll(".toggle-btn").forEach(btn => {
      btn.classList.remove("active")
    })
    clickedBtn.classList.add("active")

    // Fetch just the kanban partial from the server (for AJAX)
    const url = tab
  ? `${this.urlValue}?tab=${tab}&partial=true`
  : `${this.urlValue}?partial=true`
    const response = await fetch(url, {
      headers: { "X-Requested-With": "XMLHttpRequest" }
    })
    const html     = await response.text()

    // Swap the board content
    this.boardTarget.innerHTML = html

    // Re-attach card click listeners on the new cards
    this.boardTarget.querySelectorAll(".task-card[data-href]").forEach(card => {
      card.addEventListener("click", () => {
        window.location.href = card.dataset.href
      })
    })
  }
}
