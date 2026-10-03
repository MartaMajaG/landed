import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// AI reply bubble: shows "taking longer than usual" after a timeout,
// and lets the user retry a slow or failed answer.
export default class extends Controller {
  static targets = ["spinner", "slow"]
  static values = { url: String, timeout: Number }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.showSlow(), this.timeoutValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  showSlow() {
    if (this.hasSpinnerTarget) this.spinnerTarget.hidden = true
    if (this.hasSlowTarget) this.slowTarget.hidden = false
  }

  async retry(event) {
    const button = event.currentTarget
    button.disabled = true
    button.style.opacity = "0.6"

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": token, "Accept": "text/vnd.turbo-stream.html" }
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      button.disabled = false
      button.style.opacity = ""
    }
  }
}
