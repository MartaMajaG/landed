import { Controller } from "@hotwired/stimulus"

const ICON = {
  check: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>',
  clock: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>'
}

// Same rule as Task.assign_due_dates, so the preview matches the dashboard.
const PHASES = [
  { urgency: "high",   title: "Do these first",   offset: (arrival, today) => new Date(Math.max(addDays(arrival, -7), today)) },
  { urgency: "medium", title: "First two weeks",  offset: (arrival) => addDays(arrival, 14) },
  { urgency: "low",    title: "First month",      offset: (arrival) => addDays(arrival, 30) }
]

function addDays(date, n) { const d = new Date(date); d.setDate(d.getDate() + n); return d }
function startOfToday() { const d = new Date(); d.setHours(0, 0, 0, 0); return d }
function toISO(d) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}` }
function fromISO(s) { const [y, m, d] = s.split("-").map(Number); return new Date(y, m - 1, d) }
function fmt(d) { return d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }) }
function esc(s) { const el = document.createElement("span"); el.textContent = s ?? ""; return el.innerHTML }

export default class extends Controller {
  static targets = [
    "form", "stage", "step", "stepLabel", "progressBar",
    "dateInput", "monthLabel", "calendarGrid",
    "fact", "taskCount",
    "generating", "genLine", "genCity",
    "plan", "planTitle", "planLede", "planStats", "planBody", "planNext", "planCta"
  ]

  static values = {
    currentStep: Number,
    totalSteps: Number,
    tasks: Array,
    icons: Object
  }

  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const start = this.dateInputTarget.value ? fromISO(this.dateInputTarget.value) : startOfToday()
    this.calendarMonth = start.getMonth()
    this.calendarYear = start.getFullYear()
    this.renderCalendar()
    this.syncSummary()
    this.showCurrentStep(false)

    this.onKey = this.handleKey.bind(this)
    document.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey)
    clearTimeout(this.advanceTimer)
    this.genTimers?.forEach(clearTimeout)
  }

  // ── Navigation ──

  next(event) {
    event?.preventDefault()
    const step = this.currentStep
    if (!this.currentStepIsValid()) return this.showStepError(step)
    this.clearStepError(step)
    if (this.currentStepValue === this.totalStepsValue) return this.build()
    this.currentStepValue += 1
    this.showCurrentStep()
  }

  previous(event) {
    event?.preventDefault()
    clearTimeout(this.advanceTimer)
    this.currentStepValue = Math.max(this.currentStepValue - 1, 1)
    this.showCurrentStep()
  }

  get currentStep() { return this.stepTargets[this.currentStepValue - 1] }

  showCurrentStep(animate = true) {
    this.stepTargets.forEach((step, i) => {
      const active = i + 1 === this.currentStepValue
      step.hidden = !active
      if (active && animate && !this.reduced) {
        step.classList.remove("ob-step--in")
        void step.offsetWidth
        step.classList.add("ob-step--in")
      }
    })
    this.stepLabelTarget.textContent = `Question ${this.currentStepValue} of ${this.totalStepsValue}`
    this.setProgress((this.currentStepValue - 1) / (this.totalStepsValue + 1))

    const focusable = this.currentStep.querySelector(".ob-option__input:checked") ||
                      this.currentStep.querySelector(".ob-option__input:not(:disabled)") ||
                      this.currentStep.querySelector(".ob-chip")
    if (animate) focusable?.focus({ preventScroll: true })
  }

  setProgress(fraction) {
    this.progressBarTarget.style.width = `${Math.round(fraction * 100)}%`
  }

  // A radio choice updates the summary and moves on after a beat
  choose(event) {
    this.clearStepError(this.currentStep)
    this.syncSummary(event.target.dataset.summaryKey)
    clearTimeout(this.advanceTimer)
    if (this.currentStepValue < this.totalStepsValue) {
      this.advanceTimer = setTimeout(() => this.next(), this.reduced ? 0 : 450)
    }
  }

  handleKey(event) {
    if (this.planTarget.hidden === false || this.generatingTarget.hidden === false) return
    if (event.metaKey || event.ctrlKey || event.altKey) return

    if (event.key === "Enter") {
      const tag = document.activeElement?.tagName
      if (tag === "BUTTON" || tag === "A") return
      event.preventDefault()
      this.next()
      return
    }

    const n = parseInt(event.key, 10)
    if (!n) return
    const inputs = [...this.currentStep.querySelectorAll(".ob-option__input:not(:disabled)")]
    if (inputs[n - 1]) {
      inputs[n - 1].checked = true
      inputs[n - 1].dispatchEvent(new Event("change", { bubbles: true }))
      inputs[n - 1].focus({ preventScroll: true })
      return
    }
    const chips = [...this.currentStep.querySelectorAll(".ob-chip")]
    if (chips[n - 1]) chips[n - 1].click()
  }

  // ── Summary panel ──

  syncSummary(popKey) {
    const values = {
      city: this.checkedLabel("city"),
      date: this.dateSummary(),
      visa: this.checkedLabel("visa"),
      home: this.checkedLabel("home")
    }
    this.factTargets.forEach((row) => {
      const key = row.dataset.key
      const value = values[key]
      row.classList.toggle("is-set", !!value)
      row.querySelector(".ob-fact__value").textContent = value || "Not set yet"
      if (key === popKey && !this.reduced) {
        row.classList.remove("is-pop")
        void row.offsetWidth
        row.classList.add("is-pop")
      }
    })
    const cityId = this.selectedCityId()
    this.taskCountTarget.textContent = cityId ? this.tasksFor(cityId).length : "–"
  }

  checkedLabel(key) {
    return this.element.querySelector(`.ob-option__input[data-summary-key="${key}"]:checked`)?.dataset.summaryLabel
  }

  dateSummary() {
    const v = this.dateInputTarget.value
    if (v) return fromISO(v).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })
    return this.dateSkipped ? "Not sure yet" : null
  }

  selectedCityId() {
    return this.element.querySelector('.ob-option__input[data-summary-key="city"]:checked')?.value
  }

  tasksFor(cityId) {
    return this.tasksValue.filter((t) => String(t.city_id) === String(cityId))
  }

  // ── Calendar ──

  quickDate(event) {
    event.preventDefault()
    const date = addDays(startOfToday(), Number(event.currentTarget.dataset.days))
    this.setDate(date)
    this.calendarMonth = date.getMonth()
    this.calendarYear = date.getFullYear()
    this.renderCalendar()
    this.markChip(event.currentTarget)
    clearTimeout(this.advanceTimer)
    this.advanceTimer = setTimeout(() => this.next(), this.reduced ? 0 : 500)
  }

  markChip(chip) {
    this.element.querySelectorAll(".ob-chip").forEach((c) => c.classList.toggle("is-selected", c === chip))
  }

  previousMonth(event) {
    event.preventDefault()
    if (this.calendarMonth === 0) { this.calendarMonth = 11; this.calendarYear -= 1 } else { this.calendarMonth -= 1 }
    this.renderCalendar()
  }

  nextMonth(event) {
    event.preventDefault()
    if (this.calendarMonth === 11) { this.calendarMonth = 0; this.calendarYear += 1 } else { this.calendarMonth += 1 }
    this.renderCalendar()
  }

  renderCalendar() {
    this.monthLabelTarget.textContent = new Date(this.calendarYear, this.calendarMonth, 1)
      .toLocaleDateString("en-GB", { month: "long", year: "numeric" })

    const firstWeekday = (new Date(this.calendarYear, this.calendarMonth, 1).getDay() + 6) % 7 // Monday first
    const daysInMonth = new Date(this.calendarYear, this.calendarMonth + 1, 0).getDate()
    const selected = this.dateInputTarget.value
    const todayISO = toISO(startOfToday())
    const grid = this.calendarGridTarget
    grid.innerHTML = ""

    for (let i = 0; i < firstWeekday; i++) grid.appendChild(document.createElement("span"))

    for (let day = 1; day <= daysInMonth; day++) {
      const iso = toISO(new Date(this.calendarYear, this.calendarMonth, day))
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "ob-cal__day"
      btn.dataset.date = iso
      btn.dataset.action = "onboarding#selectDate"
      btn.textContent = day
      if (iso === todayISO) btn.classList.add("is-today")
      if (iso === selected) btn.classList.add("is-selected")
      grid.appendChild(btn)
    }
  }

  selectDate(event) {
    event.preventDefault()
    this.setDate(fromISO(event.currentTarget.dataset.date))
    this.calendarGridTarget.querySelectorAll(".ob-cal__day").forEach((d) => d.classList.toggle("is-selected", d === event.currentTarget))
    this.markChip(null)
  }

  setDate(date) {
    this.dateSkipped = false
    this.dateInputTarget.value = toISO(date)
    this.syncSummary("date")
  }

  skipDate(event) {
    event.preventDefault()
    this.dateInputTarget.value = ""
    this.dateSkipped = true
    this.markChip(null)
    this.renderCalendar()
    this.syncSummary("date")
    this.currentStepValue += 1
    this.showCurrentStep()
  }

  // ── Validation ──

  currentStepIsValid() {
    const step = this.currentStep
    const names = new Set([...step.querySelectorAll("input[type=radio][required]")].map((el) => el.name))
    return [...names].every((name) => step.querySelector(`input[type=radio][name="${name}"]:checked`))
  }

  showStepError(step) {
    let msg = step.querySelector(".ob-error")
    if (!msg) {
      msg = document.createElement("p")
      msg.className = "ob-error"
      msg.setAttribute("role", "alert")
      msg.textContent = "Pick one option to continue."
      step.querySelector(".ob-actions").before(msg)
    }
    msg.hidden = false
  }

  clearStepError(step) {
    const msg = step?.querySelector(".ob-error")
    if (msg) msg.hidden = true
  }

  // ── Build the plan ──

  build(event) {
    event?.preventDefault()
    clearTimeout(this.advanceTimer)
    if (!this.currentStepIsValid()) return this.showStepError(this.currentStep)

    const tasks = this.tasksFor(this.selectedCityId())
    if (tasks.length === 0) return this.formTarget.requestSubmit()

    const city = this.checkedLabel("city")
    this.genCityTarget.textContent = `Matching offices in ${city}`
    this.stageTarget.hidden = true
    this.generatingTarget.hidden = false
    this.stepLabelTarget.textContent = "Building your plan"
    this.setProgress(this.totalStepsValue / (this.totalStepsValue + 1))
    window.scrollTo({ top: 0 })

    const lines = this.genLineTargets
    const step = this.reduced ? 0 : 650
    this.genTimers = []
    lines.forEach((line, i) => {
      this.genTimers.push(setTimeout(() => {
        if (i > 0) lines[i - 1].className = "is-done"
        line.className = "is-active"
      }, i * step))
    })
    this.genTimers.push(setTimeout(() => {
      lines[lines.length - 1].className = "is-done"
      this.genTimers.push(setTimeout(() => this.showPlan(tasks, city), this.reduced ? 0 : 400))
    }, lines.length * step))
  }

  showPlan(tasks, city) {
    const today = startOfToday()
    const arrival = this.dateInputTarget.value ? fromISO(this.dateInputTarget.value) : null

    const phases = PHASES.map((phase) => {
      const due = arrival ? phase.offset(arrival, today) : null
      return { ...phase, due, items: tasks.filter((t) => t.urgency === phase.urgency) }
    }).filter((p) => p.items.length)

    const first = phases[0]
    this.planTitleTarget.textContent = `Your plan for ${city} is ready`
    this.planLedeTarget.textContent = arrival
      ? `${tasks.length} tasks across housing, money, legal and health, dated from your arrival on ${fmt(arrival)}.`
      : `${tasks.length} tasks across housing, money, legal and health. Add your arrival date in your profile to get deadlines.`

    this.planStatsTarget.innerHTML = `
      <div class="ob-stat"><b>${tasks.length}</b><span>tasks</span></div>
      <div class="ob-stat ob-stat--lime"><b>${first.items.length}</b><span>to do first</span></div>
      ${first.due ? `<div class="ob-stat"><b>${fmt(first.due)}</b><span>first deadline</span></div>` : ""}`

    this.planBodyTarget.style.setProperty("--cols", phases.length)
    this.planBodyTarget.innerHTML = phases.map((phase) => `
      <div class="ob-phase">
        <h3>${phase.title} <span class="ob-phase__count">${phase.items.length}</span></h3>
        <p class="ob-phase__range">${phase.due ? `By ${fmt(phase.due)}` : "No date yet"}</p>
        <div class="ob-phase__cards">
          ${phase.items.map((t) => `
            <article class="ob-task ob-task--${esc(t.pillar_slug)}">
              <p class="ob-task__name">${esc(t.name)}</p>
              ${t.why ? `<p class="ob-task__why">${esc(t.why)}</p>` : ""}
              <div class="ob-task__row">
                ${t.pillar_slug ? `<span class="ob-pill tag-pillar--${esc(t.pillar_slug)}"><span class="ob-pill__icon">${this.iconsValue[t.pillar_slug] || ""}</span>${esc(t.pillar_name)}</span>` : "<span></span>"}
                ${phase.due ? `<span class="ob-task__due">${ICON.clock}${fmt(phase.due)}</span>` : ""}
              </div>
            </article>`).join("")}
        </div>
      </div>`).join("")

    this.planNextTarget.innerHTML = `Start with <b>${esc(first.items[0].name)}</b>. It unlocks most of what comes after.`

    this.generatingTarget.hidden = true
    this.planTarget.hidden = false
    this.stepLabelTarget.textContent = "Your plan"
    this.setProgress(1)

    // One orchestrated reveal: phase by phase, card by card
    const cards = [...this.planBodyTarget.querySelectorAll(".ob-task")]
    if (this.reduced) {
      cards.forEach((c) => c.classList.add("is-in"))
      this.planCtaTarget.classList.add("is-in")
      return
    }
    cards.forEach((card, i) => setTimeout(() => card.classList.add("is-in"), 200 + i * 90))
    setTimeout(() => this.planCtaTarget.classList.add("is-in"), 300 + cards.length * 90)
  }
}
