import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="smart-actions"
export default class extends Controller {
  static values = {
    type: String,
    url: String,
    taskId: String
  }

  connect() {
    console.log("Smart Actions Controller connected for type:", this.typeValue)
  }

  // Primary action triggered when the "Smart Action" button is clicked
  perform(event) {
    event.preventDefault()

    switch (this.typeValue) {
      case "download_and_send_to_employer":
        this.downloadTemplate()
        break
      case "link_to_external_search":
        this.openExternalLink()
        break
      case "verify_validity":
        this.triggerVerificationFlow()
        break
      default:
        console.warn("Unknown action type:", this.typeValue)
    }
  }

  downloadTemplate() {
    if (this.urlValue) {
      window.open(this.urlValue, "_blank")
    }
  }

  openExternalLink() {
    if (this.urlValue) {
      window.open(this.urlValue, "_blank")
    }
  }

  triggerVerificationFlow() {
    // Logic for identity/passport verification (placeholder for future Sprint)
    alert("Starting document validity verification...")
  }
}
