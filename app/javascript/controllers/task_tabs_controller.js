import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["board"]
  static values  = { url: String }

  connect() {
    // Place the sliding pill under the active tab without animating on load
    requestAnimationFrame(() => this.movePill(this.element.querySelector(".toggle-btn.active"), false))
  }

  // Slides the white pill behind the chosen tab
  movePill(btn, animate = true) {
    const pill = this.element.querySelector(".tasks-toggle__pill")
    if (!pill || !btn) return
    pill.classList.toggle("tasks-toggle__pill--instant", !animate)
    pill.style.width = `${btn.offsetWidth}px`
    pill.style.transform = `translateX(${btn.offsetLeft}px)`
    pill.classList.add("tasks-toggle__pill--ready")
  }

  async switchTab(event) {
    const clickedBtn = event.currentTarget
    const tab        = clickedBtn.dataset.tab

    // Swap active class on buttons
    this.element.querySelectorAll(".toggle-btn").forEach(btn => {
      btn.classList.remove("active")
    })
    clickedBtn.classList.add("active")
    this.movePill(clickedBtn)

    // Fetch just the kanban partial from the server (for AJAX)
    const url = tab
  ? `${this.urlValue}?tab=${tab}&partial=true`
  : `${this.urlValue}?partial=true`
    const response = await fetch(url, {
      headers: { "X-Requested-With": "XMLHttpRequest" }
    })
    const html     = await response.text()

    // Swap the board content, with a short fade-in
    this.boardTarget.innerHTML = html
    this.boardTarget.classList.remove("board-fade-in")
    void this.boardTarget.offsetWidth
    this.boardTarget.classList.add("board-fade-in")

    // Re-attach card click listeners on the new cards
    this.boardTarget.querySelectorAll(".task-card[data-href]").forEach(card => {
      card.addEventListener("click", () => {
        window.location.href = card.dataset.href
      })
    })
  }
}
