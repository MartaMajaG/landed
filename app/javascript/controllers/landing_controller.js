import { Controller } from "@hotwired/stimulus"

// Landing page motion: sections fade in once as they scroll into view,
// and the hero demo's "done" counter ticks up when the Anmeldung row checks itself off.
export default class extends Controller {
  static targets = ["reveal"]

  connect() {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (reduced || !("IntersectionObserver" in window)) {
      this.revealTargets.forEach((el) => el.classList.add("is-in"))
    } else {
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          entry.target.classList.add("is-in")
          this.observer.unobserve(entry.target)
        })
      }, { threshold: 0.2, rootMargin: "0px 0px -60px 0px" })
      this.revealTargets.forEach((el) => this.observer.observe(el))
    }

    const done = this.element.querySelector(".lp-demo__done")
    if (done) this.tickTimer = setTimeout(() => { done.textContent = "2" }, reduced ? 0 : 2400)
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.tickTimer)
  }
}
