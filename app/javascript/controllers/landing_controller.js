import { Controller } from "@hotwired/stimulus"

// Landing page motion: sections fade in once as they scroll into view, the hero illustration
// drifts with scroll, and the product preview (real dashboard cards) plays a short sequence:
// two Anmeldung steps get ticked off, then the Banking card shows its hover state.
export default class extends Controller {
  static targets = ["reveal", "scene", "sceneMedia", "demo"]

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
          if (this.hasDemoTarget && entry.target.contains(this.demoTarget)) this.playDemo(false)
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

    // Without motion the preview shows its end state straight away;
    // otherwise it plays when the product section scrolls into view (see observer above)
    if (this.hasDemoTarget && (reduced || !("IntersectionObserver" in window))) this.playDemo(true)
  }

  playDemo(reduced) {
    this.timers = []
    const card = this.demoTarget.querySelector(".lp-demo__progress .task-card")
    const hover = this.demoTarget.querySelector(".lp-demo__hover .task-card")
    const at = (ms, fn) => this.timers.push(setTimeout(fn, reduced ? 0 : ms))

    if (card) {
      const total = Number(card.dataset.total)
      const setStep = (done) => {
        const pct = Math.round((done / total) * 100)
        const label = card.querySelector(".card-progress-label")
        const pctEl = card.querySelector(".card-pct")
        label.textContent = `${done}/${total} steps`
        pctEl.textContent = `${pct}%`
        card.querySelector(".card-fill").style.width = `${pct}%`
        if (!reduced) {
          ;[label, pctEl].forEach((el) => { el.classList.remove("is-bump"); void el.offsetWidth; el.classList.add("is-bump") })
        }
      }
      if (reduced) setStep(2)
      else { at(2200, () => setStep(1)); at(3300, () => setStep(2)) }
    }

    if (hover && !reduced) {
      at(4300, () => hover.classList.add("is-hover"))
      at(5900, () => hover.classList.remove("is-hover"))
    }
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
    this.timers?.forEach(clearTimeout)
  }
}
