import { Controller } from "@hotwired/stimulus"

// Swaps the upload form for the "analysing" state.
// If a photo was chosen, it's shown with a scan line sweeping over it.
export default class extends Controller {
  static targets = ["form", "loader", "scan", "scanImage", "spinner"]

  submit() {
    const preview = this.element.querySelector('[data-uploadpreview-target="preview"]')
    const hasPhoto = preview && preview.getAttribute("src") && !preview.classList.contains("d-none")

    if (hasPhoto && this.hasScanTarget && this.hasScanImageTarget) {
      this.scanImageTarget.src = preview.src
      this.scanTarget.classList.remove("d-none")
      if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("d-none")
    }

    this.formTarget.classList.add("d-none")
    this.loaderTarget.classList.remove("d-none")
  }
}
