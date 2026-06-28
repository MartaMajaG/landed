import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "stepCount", "autosave", "completionOverlay"]

  connect() {
    console.log("Task detail controller connected")
    const sidebar = document.querySelector('.task-sidebar')
    const stepsEl = document.querySelector('.task-why')
    if (sidebar && stepsEl) {
      requestAnimationFrame(() => {
        const sidebarRect = sidebar.getBoundingClientRect()
        sidebar.style.left = sidebarRect.left + 'px'
        sidebar.style.width = sidebarRect.width + 'px'
      })
    }
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
      numberEl.classList.add("step__number--done")
      numberEl.innerHTML = `
        <form action="${url}" method="post" data-turbo="false">
          <input type="hidden" name="_method" value="patch">
          <input type="hidden" name="authenticity_token" value="${document.querySelector('meta[name="csrf-token"]').content}">
          <button type="submit" class="step__undo-btn" data-action="click->task-detail#undoStep" title="Mark as incomplete">
            <span class="step__check">✓</span>
          </button>
        </form>
      `

      const checkboxForm = stepEl.querySelector(".step__checkbox-form")
      if (checkboxForm) checkboxForm.style.display = "none"

      const toggleBtn = stepEl.querySelector(".step__toggle")
      if (toggleBtn) toggleBtn.style.display = "none"

      const allSteps = this.stepTargets
      const currentIndex = allSteps.indexOf(stepEl)
      const nextStep = allSteps[currentIndex + 1]

      if (nextStep) {
        nextStep.classList.remove("step--locked")
        nextStep.classList.add("step--active")
        const nextCheckbox = nextStep.querySelector(".step__checkbox-form")
        if (nextCheckbox) nextCheckbox.style.display = ""
        const nextToggle = nextStep.querySelector(".step__toggle")
        if (nextToggle) nextToggle.style.display = ""
        const nextUnlockHint = nextStep.querySelector(".step__unlock-hint")
        if (nextUnlockHint) nextUnlockHint.style.display = "none"

        // Always scroll to next step, even if already in view
        this.scrollToStep(nextStep)
      }

      const completedCount = this.stepTargets.filter(s => s.classList.contains("step--completed")).length
      const totalCount = this.stepTargets.length

      if (completedCount === totalCount) {
        this.stepCountTarget.textContent = `All steps complete!`
      } else {
        this.stepCountTarget.textContent = `Step ${completedCount + 1} of ${totalCount}`
      }

      this.flashAutosave()

      if (completedCount === totalCount) {
        this.celebrate()
      }
    }
  }

  async undoStep(event) {
    event.preventDefault()

    const form = event.target.closest("form")
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
      stepEl.classList.remove("step--completed")
      stepEl.classList.add("step--active")

      const numberEl = stepEl.querySelector(".step__number")
      numberEl.classList.remove("step__number--done")
      numberEl.innerHTML = `<span>${this.stepTargets.indexOf(stepEl) + 1}</span>`

      const checkboxForm = stepEl.querySelector(".step__checkbox-form")
      if (checkboxForm) checkboxForm.style.display = ""

      const toggleBtn = stepEl.querySelector(".step__toggle")
      if (toggleBtn) toggleBtn.style.display = ""

      const allSteps = this.stepTargets
      const currentIndex = allSteps.indexOf(stepEl)
      const nextStep = allSteps[currentIndex + 1]
      if (nextStep) {
        nextStep.classList.remove("step--active")
        nextStep.classList.add("step--locked")
        const nextCheckbox = nextStep.querySelector(".step__checkbox-form")
        if (nextCheckbox) nextCheckbox.style.display = "none"
        const nextToggle = nextStep.querySelector(".step__toggle")
        if (nextToggle) nextToggle.style.display = "none"
      }

      const completedCount = this.stepTargets.filter(s => s.classList.contains("step--completed")).length
      const totalCount = this.stepTargets.length
      this.stepCountTarget.textContent = `Step ${completedCount + 1} of ${totalCount}`

      this.flashAutosave()
    }
  }

  scrollToStep(stepEl) {
    const OFFSET = 120 // px from top of viewport — adjust to clear your nav
    const top = stepEl.getBoundingClientRect().top + window.scrollY - OFFSET
    window.scrollTo({ top, behavior: "smooth" })
  }

  flashAutosave() {
    const el = this.autosaveTarget
    el.style.opacity = "1"
    setTimeout(() => {
      el.style.opacity = "0"
    }, 2000)
  }

  celebrate() {
    this.launchParticleShimmer()

    setTimeout(() => {
      const overlay = this.completionOverlayTarget
      overlay.classList.add("is-visible")
      const bar = overlay.querySelector(".completion-overlay__bar-fill")
      setTimeout(() => { bar.style.width = "100%" }, 50)
    }, 600)

    setTimeout(() => {
      window.location.href = "/"
    }, 4500)
  }

  launchParticleShimmer() {
    const canvas = document.createElement('canvas')
    canvas.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:999;'
    document.body.appendChild(canvas)
    const ctx = canvas.getContext('2d')
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight

    const cx = canvas.width / 2
    const cy = canvas.height / 2

    const colors = ['#5B50E8', '#7A9E1F', '#A89CFF', '#C8F59A', '#ffffff', '#E8E5FB']
    const particles = []

    for (let i = 0; i < 160; i++) {
      const angle = (Math.random() * Math.PI * 2)
      const speed = 1.2 + Math.random() * 3.5
      particles.push({
        x: cx + (Math.random() - 0.5) * 100,
        y: cy + (Math.random() - 0.5) * 100,
        vx: Math.cos(angle) * speed * 0.5,
        vy: -(1.5 + Math.random() * 3.5),
        size: 3 + Math.random() * 5,
        color: colors[Math.floor(Math.random() * colors.length)],
        alpha: 0,
        alphaTarget: 0.9 + Math.random() * 0.1,
        decay: 0.008 + Math.random() * 0.006,
        twinkle: Math.random() * Math.PI * 2,
        delay: Math.random() * 20
      })
    }

    let tick = 0
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      let alive = false
      tick++

      particles.forEach(p => {
        if (tick < p.delay) { alive = true; return }

        if (p.alpha < p.alphaTarget) {
          p.alpha = Math.min(p.alphaTarget, p.alpha + 0.1)
        } else {
          p.alpha -= p.decay
        }

        if (p.alpha <= 0) return
        alive = true

        p.x += p.vx
        p.y += p.vy
        p.vy *= 0.997
        p.vx *= 0.997
        p.twinkle += 0.1
        const twinkleFactor = 0.65 + 0.35 * Math.sin(p.twinkle)

        ctx.save()
        ctx.globalAlpha = Math.max(0, p.alpha) * twinkleFactor
        ctx.fillStyle = p.color
        ctx.shadowColor = p.color
        ctx.shadowBlur = 10
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()
      })

      if (alive) {
        requestAnimationFrame(animate)
      } else {
        canvas.remove()
      }
    }
    animate()
  }
}
