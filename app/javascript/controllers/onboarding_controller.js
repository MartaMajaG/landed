import { Controller } from "@hotwired/stimulus"

const ICON = {
  check: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>',
  clock: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>'
}

// The dashboard's own columns, same urgency split and same due-date rule as
// Task#due_date_for, so the preview and the dashboard show the same board.
const COLUMNS = [
  { urgency: "high",   title: "Urgent",   key: "urgent",   offset: (arrival, today) => new Date(Math.max(addDays(arrival, -7), today)) },
  { urgency: "medium", title: "Active",   key: "active",   offset: (arrival) => addDays(arrival, 14) },
  { urgency: "low",    title: "Upcoming", key: "upcoming", offset: (arrival) => addDays(arrival, 30) }
]
const PREVIEW_PER_COLUMN = 3

function addDays(date, n) { const d = new Date(date); d.setDate(d.getDate() + n); return d }
function startOfToday() { const d = new Date(); d.setHours(0, 0, 0, 0); return d }
function toISO(d) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}` }
function fromISO(s) { const [y, m, d] = s.split("-").map(Number); return new Date(y, m - 1, d) }
// Same as ApplicationHelper#short_date: day before month, the year only when it is not this year
function fmt(d) {
  const day = `${d.getDate()} ${d.toLocaleDateString("en-US", { month: "short" })}`
  return d.getFullYear() === new Date().getFullYear() ? day : `${day} ${d.getFullYear()}`
}
// Same format as ApplicationHelper#due_label: day before month, relative word beside the date
function fmtCard(d) {
  const day = fmt(d)
  const daysLeft = Math.round((d - startOfToday()) / 86400000)
  if (daysLeft < 0) return `Overdue since ${day}`
  if (daysLeft === 0) return `Due today, ${day}`
  if (daysLeft === 1) return `Due tomorrow, ${day}`
  return `Due ${day}`
}
function esc(s) { const el = document.createElement("span"); el.textContent = s ?? ""; return el.innerHTML }

export default class extends Controller {
  static targets = [
    "visaTypes",
    "form", "stage", "step", "stepLabel", "progressBar",
    "dateInput", "monthLabel", "calendarGrid",
    "fact", "taskCount",
    "generating", "genLine", "genCity",
    "plan", "planTitle", "planLede", "planBody", "planNext", "planCta"
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
                      this.currentStep.querySelector(".ob-chip.is-selected, .ob-cal__day.is-selected") ||
                      this.currentStep.querySelector(".ob-chip")
    if (animate) focusable?.focus({ preventScroll: true })
  }

  setProgress(fraction) {
    this.progressBarTarget.style.width = `${Math.round(fraction * 100)}%`
  }

  // A radio choice only selects and updates the summary; the user moves on with Continue
  choose(event) {
    this.clearStepError(this.currentStep)
    this.syncSummary(event.target.dataset.summaryKey)
  }

  handleKey(event) {
    if (this.planTarget.hidden === false || this.generatingTarget.hidden === false) return
    if (event.metaKey || event.ctrlKey || event.altKey) return

    if (event.key === "Enter") {
      // Enter on a real action (Back, a link) keeps its own meaning. On a
      // choice the person just made (a quick pick or a calendar day) it moves
      // on, so "or press Enter" holds true on every step.
      const el = document.activeElement
      const isChoice = el?.matches?.(".ob-chip, .ob-cal__day")
      if ((el?.tagName === "BUTTON" && !isChoice) || el?.tagName === "A") return
      event.preventDefault()
      this.next()
      return
    }

    const n = parseInt(event.key, 10)
    if (!n) return
    // Only options on screen: the visa types stay hidden until "Yes"
    const inputs = [...this.currentStep.querySelectorAll(".ob-option__input:not(:disabled)")]
      .filter((input) => input.closest("[hidden]") === null)
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

  // The last checked answer wins, so "Visa needed" gives way to the visa type once one is picked
  checkedLabel(key) {
    return [...this.element.querySelectorAll(`.ob-option__input[data-summary-key="${key}"]:checked`)].pop()?.dataset.summaryLabel
  }

  // "No" stores eu_citizen straight away. "Yes" reveals the visa types and
  // clears any earlier answer, so the step only counts as done once one is picked.
  chooseVisaNeed(event) {
    const needsVisa = event.target.value === "yes"
    const euRadio = this.element.querySelector(".ob-visa-eu")
    this.visaTypesTarget.hidden = !needsVisa
    if (needsVisa) {
      euRadio.checked = false
    } else {
      euRadio.checked = true
      this.visaTypesTarget.querySelectorAll("input").forEach((input) => { input.checked = false })
    }
    this.choose(event)
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
    // No auto-advance here: the user checks the date on the calendar, then presses Continue
    this.currentStep.querySelector(".ob-actions .ob-btn:not(.ob-btn--ghost)")?.focus({ preventScroll: true })
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

  // "I don't know yet" is one of the answers, so like the other quick picks it
  // selects and waits for Continue rather than jumping ahead.
  skipDate(event) {
    event.preventDefault()
    this.dateInputTarget.value = ""
    this.dateSkipped = true
    this.markChip(event.currentTarget)
    this.renderCalendar()
    this.syncSummary("date")
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

    // Same rule as Task#due_date_for: dates count from arrival, or from today
    // (the day they join) if arrival is already past. Columns follow category.
    const start = arrival ? new Date(Math.max(arrival, today)) : null
    const columns = COLUMNS.map((col) => ({
      ...col,
      items: tasks.filter((t) => t.urgency === col.urgency)
                  .map((t) => ({ ...t, due: start ? col.offset(start, today) : null }))
    })).filter((c) => c.items.length)

    const first = columns[0]
    const urgent = columns.find((c) => c.key === "urgent")
    this.planTitleTarget.textContent = `Your board for ${city} is ready`
    this.planLedeTarget.textContent = urgent
      ? `${tasks.length} tasks, sorted by urgency. Start with the ${urgent.items.length} urgent ones. The rest move up as their deadlines get closer.`
      : `${tasks.length} tasks, sorted by urgency. The rest move up as their deadlines get closer.`

    // Compact versions of the dashboard's kanban cards: category, title, due date
    const card = (t, col, isFirst) => `
      <div class="task-card ${col.key === "urgent" ? "urgent-card" : ""} ${col.key === "upcoming" ? "locked" : ""} task-card--pillar-${esc(t.pillar_slug)} ob-card">
        <div class="card-top">
          <div class="card-tags">${t.pillar_slug ? `<span class="pillar-chip tag-pillar--${esc(t.pillar_slug)}"><span class="pillar-chip__icon">${this.iconsValue[t.pillar_slug] || ""}</span><span class="pillar-chip__label">${esc(t.pillar_name)}</span></span>` : ""}</div>
          ${isFirst ? `<span class="ob-start">Start here</span>` : ""}
        </div>
        <h4 class="card-title">${esc(t.name)}</h4>
        ${t.due ? `<div class="card-bottom-row"><span class="card-due ${col.key === "urgent" ? "urgent-due" : ""}" style="display:inline-flex; align-items:center; gap:4px;"><span class="lucide-icon">${ICON.clock}</span>${fmtCard(t.due)}</span></div>` : ""}
      </div>`

    this.planBodyTarget.innerHTML = columns.map((col) => {
      const shown = col.items.slice(0, PREVIEW_PER_COLUMN)
      const more = col.items.length - shown.length
      return `
        <div class="kanban-col">
          <div class="col-header ${col.key}-header">
            <span class="col-dot ${col.key}-dot"></span>
            <span class="col-title">${col.title}</span>
            <span class="col-count">${col.items.length}</span>
          </div>
          ${shown.map((t, i) => card(t, col, col === first && i === 0)).join("")}
          ${more > 0 ? `<p class="ob-more">+${more} more on your board</p>` : ""}
        </div>`
    }).join("")

    this.planNextTarget.innerHTML = `Start with <b>${esc(first.items[0].name)}</b>. It unlocks most of what comes after.`

    this.generatingTarget.hidden = true
    this.planTarget.hidden = false
    this.stepLabelTarget.textContent = "Your board"
    this.setProgress(1)

    // One orchestrated reveal: column by column, card by card
    const cards = [...this.planBodyTarget.querySelectorAll(".ob-card, .ob-more")]
    if (this.reduced) {
      cards.forEach((c) => c.classList.add("is-in"))
      this.planCtaTarget.classList.add("is-in")
      return
    }
    cards.forEach((c, i) => setTimeout(() => c.classList.add("is-in"), 200 + i * 90))
    setTimeout(() => this.planCtaTarget.classList.add("is-in"), 300 + cards.length * 90)
  }
}
