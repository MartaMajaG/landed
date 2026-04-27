import { Controller } from "@hotwired/stimulus"

// Attached to the chat form.
// Disables the submit button on form submission to prevent double-sending,
// and re-enables it once the Turbo Stream response (the loading bubble) arrives.
// The actual AI reply is delivered later via ActionCable by AiReplyJob.
export default class extends Controller {
  connect() {
    // Re-enable the submit button when the Turbo Stream response is received
    this.element.addEventListener("turbo:submit-end", this.enableSubmit.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.enableSubmit.bind(this))
  }

  disableSubmit(event) {
    const submitButton = this.element.querySelector("[type=submit]")
    if (submitButton) submitButton.disabled = true
  }

  enableSubmit() {
    const submitButton = this.element.querySelector("[type=submit]")
    if (submitButton) submitButton.disabled = false
  }
}
