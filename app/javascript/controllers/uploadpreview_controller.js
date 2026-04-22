import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="uploadpreview"
export default class extends Controller {
  static targets = ["input", "preview"]

  show(event) {
    const file = event.target.files[0]
    if (!file) return

    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("d-none")
  }
}
