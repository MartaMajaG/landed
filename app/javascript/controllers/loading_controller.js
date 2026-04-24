import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["form", "loader"]

  submit() {
    this.formTarget.classList.add("d-none")
    this.loaderTarget.classList.remove("d-none")
  }
}
