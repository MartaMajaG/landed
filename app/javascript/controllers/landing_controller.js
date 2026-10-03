import { Controller } from "@hotwired/stimulus"

// Landing page motion: sections fade in once as they scroll into view,
// and the hero demo's "done" counter ticks up when the Anmeldung row checks itself off.
export default class extends Controller {
  static targets = ["reveal", "scene", "sceneMedia"]

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

    if (!reduced && this.hasSceneTarget) {
      this.onScroll = () => {
        if (this.frame) return
        this.frame = requestAnimationFrame(() => { this.frame = null; this.parallax() })
      }
      window.addEventListener("scroll", this.onScroll, { passive: true })
      window.addEventListener("resize", this.onScroll, { passive: true })
      this.parallax()
    }

    const done = this.element.querySelector(".lp-demo__done")
    if (done) this.tickTimer = setTimeout(() => { done.textContent = "2" }, reduced ? 0 : 2400)
  }

  // The illustration zooms out and drifts slightly as it scrolls through the viewport
  parallax() {
    const rect = this.sceneTarget.getBoundingClientRect()
    const vh = window.innerHeight
    if (rect.bottom < 0 || rect.top > vh) return
    const progress = Math.min(Math.max((vh - rect.top) / (vh + rect.height), 0), 1)
    this.sceneMediaTarget.style.setProperty("--ps", (1.12 - progress * 0.1).toFixed(4))
    this.sceneMediaTarget.style.setProperty("--py", `${((0.5 - progress) * 36).toFixed(1)}px`)
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.observer?.disconnect()
    clearTimeout(this.tickTimer)
  }
}
