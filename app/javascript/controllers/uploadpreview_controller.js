import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="uploadpreview"
export default class extends Controller {
  static targets = ["input", "preview", "filename"]

  show(event) {
    const file = event.target.files[0]
    if (!file) return

    if (file.type.startsWith("image/")) {
      this.previewTarget.src = URL.createObjectURL(file)
      this.previewTarget.classList.remove("d-none")
      this.filenameTarget.classList.add("d-none")
    } else {
      this.previewTarget.classList.add("d-none")
      this.filenameTarget.textContent = file.name
      this.filenameTarget.classList.remove("d-none")
    }
  }
}
