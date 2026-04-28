import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "stepLabel", "percentLabel", "progressBar", "dateInput", "monthLabel", "calendarGrid"]

  static values = {
    currentStep: Number,
    totalSteps: Number
  }

  connect() {
    const today = new Date()
    this.calendarMonth = today.getMonth()
    this.calendarYear = today.getFullYear()
    this.renderCalendar()
    this.showCurrentStep()
  }

  next(event) {
    event.preventDefault()

    if (!this.currentStepIsValid()) {
      this.showStepError(this.stepTargets[this.currentStepValue - 1])
      return
    }

    this.clearStepError(this.stepTargets[this.currentStepValue - 1])
    this.currentStepValue = Math.min(this.currentStepValue + 1, this.totalStepsValue)
    this.showCurrentStep()
  }

  previous(event) {
    event.preventDefault()

    this.currentStepValue = Math.max(this.currentStepValue - 1, 1)
    this.showCurrentStep()
  }

  showCurrentStep() {
    this.stepTargets.forEach((step, index) => {
      step.hidden = index + 1 !== this.currentStepValue
    })

    const percent = Math.round((this.currentStepValue / this.totalStepsValue) * 100)

    this.stepLabelTarget.textContent = `STEP ${this.currentStepValue} OF ${this.totalStepsValue}`
    this.percentLabelTarget.textContent = `${percent}% COMPLETE`
    this.progressBarTarget.style.width = `${percent}%`
  }

  // calendar

  previousMonth(event) {
    event.preventDefault()
    if (this.calendarMonth === 0) {
      this.calendarMonth = 11
      this.calendarYear -= 1
    } else {
      this.calendarMonth -= 1
    }
    this.renderCalendar()
  }

  nextMonth(event) {
    event.preventDefault()
    if (this.calendarMonth === 11) {
      this.calendarMonth = 0
      this.calendarYear += 1
    } else {
      this.calendarMonth += 1
    }
    this.renderCalendar()
  }

  renderCalendar() {
    const label = new Date(this.calendarYear, this.calendarMonth, 1)
      .toLocaleDateString("en-US", { month: "long", year: "numeric" })
    this.monthLabelTarget.textContent = label

    const firstDay = new Date(this.calendarYear, this.calendarMonth, 1).getDay()
    const daysInMonth = new Date(this.calendarYear, this.calendarMonth + 1, 0).getDate()
    const selectedDate = this.dateInputTarget.value

    const grid = this.calendarGridTarget
    grid.innerHTML = ""

    for (let i = 0; i < firstDay; i++) {
      grid.appendChild(document.createElement("span"))
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const month = String(this.calendarMonth + 1).padStart(2, "0")
      const dayStr = String(day).padStart(2, "0")
      const dateStr = `${this.calendarYear}-${month}-${dayStr}`

      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "onboarding-calendar-day"
      btn.dataset.date = dateStr
      btn.dataset.action = "onboarding#selectDate"
      btn.textContent = day
      if (selectedDate === dateStr) btn.classList.add("is-selected")

      grid.appendChild(btn)
    }
  }

  selectDate(event) {
    event.preventDefault()

    this.dateInputTarget.value = event.currentTarget.dataset.date

    this.calendarGridTarget.querySelectorAll(".onboarding-calendar-day").forEach((day) => {
      day.classList.remove("is-selected")
    })

    event.currentTarget.classList.add("is-selected")
  }

  skipDate(event) {
    event.preventDefault()

    this.dateInputTarget.value = ""

    this.calendarGridTarget.querySelectorAll(".onboarding-calendar-day").forEach((day) => {
      day.classList.remove("is-selected")
    })

    this.currentStepValue = Math.min(this.currentStepValue + 1, this.totalStepsValue)
    this.showCurrentStep()
  }

  // validation

  currentStepIsValid() {
    const step = this.stepTargets[this.currentStepValue - 1]
    const names = new Set([...step.querySelectorAll("input[type=radio][required]")].map(el => el.name))
    return [...names].every(name => step.querySelector(`input[type=radio][name="${name}"]:checked`))
  }

  showStepError(step) {
    let msg = step.querySelector(".onboarding-step-error")
    if (!msg) {
      msg = document.createElement("p")
      msg.className = "onboarding-step-error"
      msg.textContent = "Please make a selection to continue."
      step.querySelector(".onboarding-actions").before(msg)
    }
    msg.hidden = false
  }

  clearStepError(step) {
    const msg = step.querySelector(".onboarding-step-error")
    if (msg) msg.hidden = true
  }
}
