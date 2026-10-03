import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="uploadpreview"
// Shows a preview of the chosen photo, or an error when the file can't be scanned (e.g. a PDF).
export default class extends Controller {
  static targets = ["input", "preview", "filename", "error", "errorName"]

  show(event) {
    const file = event.target.files[0]
    if (!file) return

    const submit = this.element.closest("form")?.querySelector('[type="submit"]')

    // Only images can be scanned; anything else shows the error and blocks submitting
    if (!file.type.startsWith("image/")) {
      this.previewTarget.classList.add("d-none")
      this.filenameTarget.classList.add("d-none")
      if (this.hasErrorNameTarget) this.errorNameTarget.textContent = `“${file.name}”`
      if (this.hasErrorTarget) {
        this.errorTarget.classList.remove("d-none")
        this.errorTarget.style.display = "flex"
      }
      event.target.value = ""
      if (submit) {
        submit.disabled = true
        submit.style.opacity = "0.5"
        submit.style.cursor = "not-allowed"
      }
      return
    }

    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("d-none")
      this.errorTarget.style.display = ""
    }
    if (submit) {
      submit.disabled = false
      submit.style.opacity = ""
      submit.style.cursor = ""
    }

    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("d-none")
    this.filenameTarget.classList.add("d-none")
  }
}
