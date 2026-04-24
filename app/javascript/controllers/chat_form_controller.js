import { Controller } from "@hotwired/stimulus"

// Attached to the chat form.
// Shows a loading overlay on submit, hides it when the Turbo Stream response arrives.
export default class extends Controller {
  connect() {
    // Listen for turbo:submit-end on the form to hide the loader after the response arrives
    this.element.addEventListener("turbo:submit-end", this.hideLoader.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.hideLoader.bind(this))
  }

  showLoader(event) {
    const overlay = document.getElementById("chat-loading-overlay")
    if (overlay) {
      overlay.style.display = "flex"
    }
    // Disable submit button to prevent double-submission
    const submitButton = this.element.querySelector("[type=submit]")
    if (submitButton) submitButton.disabled = true
  }

  hideLoader() {
    const overlay = document.getElementById("chat-loading-overlay")
    if (overlay) {
      overlay.style.display = "none"
    }
    // Re-enable submit button
    const submitButton = this.element.querySelector("[type=submit]")
    if (submitButton) submitButton.disabled = false
  }
}
