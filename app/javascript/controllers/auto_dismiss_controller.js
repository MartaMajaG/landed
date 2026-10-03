import { Controller } from "@hotwired/stimulus"

// Fades out a flash message after a few seconds.
// Pauses while hovered or focused, so people can still read it or click close.
export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.start()
    this.element.addEventListener("mouseenter", this.stop)
    this.element.addEventListener("mouseleave", this.start)
    this.element.addEventListener("focusin", this.stop)
  }

  disconnect() {
    this.stop()
    this.element.removeEventListener("mouseenter", this.stop)
    this.element.removeEventListener("mouseleave", this.start)
    this.element.removeEventListener("focusin", this.stop)
  }

  start = () => {
    this.stop()
    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  stop = () => {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.remove("show")          // Bootstrap's fade transition
    setTimeout(() => this.element.remove(), 300)
  }
}
