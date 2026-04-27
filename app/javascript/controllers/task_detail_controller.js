import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "stepCount", "autosave", "completionOverlay"]

  connect() {
    console.log("Task detail controller connected")
  }

  async completeStep(event) {
    event.preventDefault()

    const form = event.target
    const url = form.action

    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    })

    if (response.ok) {
      const stepEl = form.closest(".step")

      stepEl.classList.remove("step--active")
      stepEl.classList.add("step--completed")

      const numberEl = stepEl.querySelector(".step__number")
      numberEl.innerHTML = '<span class="step__check">✓</span>'

      const checkboxForm = stepEl.querySelector(".step__checkbox-form")
      if (checkboxForm) checkboxForm.style.display = "none"

      const allSteps = this.stepTargets
      const currentIndex = allSteps.indexOf(stepEl)
      const nextStep = allSteps[currentIndex + 1]

      if (nextStep) {
        nextStep.classList.remove("step--locked")
        nextStep.classList.add("step--active")
        const nextCheckbox = nextStep.querySelector(".step__checkbox-form")
        if (nextCheckbox) nextCheckbox.style.display = "block"
      }

      const completedCount = this.stepTargets.filter(s => s.classList.contains("step--completed")).length
      const totalCount = this.stepTargets.length
      const percentage = Math.round((completedCount / totalCount) * 100)
      this.progressBarTarget.style.width = `${percentage}%`
      this.stepCountTarget.textContent = `Step ${completedCount + 1} of ${totalCount}`

      this.flashAutosave()

      if (completedCount === totalCount) {
        this.celebrate()
      }
    }
  }

  flashAutosave() {
    const el = this.autosaveTarget
    el.style.opacity = "1"
    setTimeout(() => {
      el.style.opacity = "0"
    }, 2000)
  }

  celebrate() {
    confetti({
      particleCount: 150,
      spread: 80,
      origin: { y: 0.6 },
      colors: ["#2563EB", "#7A9E1F", "#F59E0B", "#ffffff"]
    })

    setTimeout(() => {
      confetti({
        particleCount: 80,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: ["#2563EB", "#7A9E1F"]
      })
    }, 300)

    setTimeout(() => {
      confetti({
        particleCount: 80,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: ["#2563EB", "#7A9E1F"]
      })
    }, 500)

    setTimeout(() => {
      const overlay = this.completionOverlayTarget
      overlay.classList.add("is-visible")
      const bar = overlay.querySelector(".completion-overlay__bar-fill")
      setTimeout(() => { bar.style.width = "100%" }, 50)
    }, 800)

    setTimeout(() => {
      window.location.href = "/dashboard"
    }, 4000)
  }
}
