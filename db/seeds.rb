require 'open-uri'

# ─────────────────────────────────────────────────────────────────────────────
# CITIES
# ─────────────────────────────────────────────────────────────────────────────
berlin  = City.find_or_create_by!(name: "Berlin",  country: "Germany")
munich  = City.find_or_create_by!(name: "Munich",  country: "Germany")
hamburg = City.find_or_create_by!(name: "Hamburg", country: "Germany")
puts "Cities seeded: #{City.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# PILLARS  (per SeedingBestPractice.md — 4 pillars, stable slugs)
# ─────────────────────────────────────────────────────────────────────────────
# Slug is the stable key — never change it once in production.
pillar_legal = Pillar.find_or_create_by!(slug: "legal_and_work", city: munich) do |p|
  p.name        = "Legal & Work"
  p.description = "Visa, residence permit, employment documents, and degree recognition."
  p.icon        = "fa-briefcase"
  p.position    = 1
end

pillar_housing = Pillar.find_or_create_by!(slug: "housing_and_registration", city: munich) do |p|
  p.name        = "Housing & Registration"
  p.description = "Register your address, set up utilities, and pay the broadcasting fee."
  p.icon        = "fa-house"
  p.position    = 2
end

pillar_finance = Pillar.find_or_create_by!(slug: "finance_and_banking", city: munich) do |p|
  p.name        = "Finance & Banking"
  p.description = "Open a bank account, obtain your Tax ID, and file your first tax return."
  p.icon        = "fa-building-columns"
  p.position    = 3
end

pillar_health = Pillar.find_or_create_by!(slug: "health_and_insurance", city: munich) do |p|
  p.name        = "Health & Insurance"
  p.description = "Choose a health insurance provider and secure your mandatory coverage."
  p.icon        = "fa-notes-medical"
  p.position    = 4
end

puts "Pillars seeded: #{Pillar.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# DOCUMENT TYPES  (static knowledge base — never modified at runtime)
# ─────────────────────────────────────────────────────────────────────────────
puts "Seeding Document Types..."
doc_types_path = Rails.root.join('db', 'seeds', 'data', 'document_types.json')
doc_types_data = JSON.parse(File.read(doc_types_path))

doc_types_data.each do |data|
  DocumentType.find_or_create_by!(slug: data['id']) do |dt|
    dt.name        = data['name']
    dt.master_data = data
  end
end
puts "Document Types seeded: #{DocumentType.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# MAIN TASKS  (assigned to their correct Pillar)
# ─────────────────────────────────────────────────────────────────────────────

# Pillar 2 — Housing & Registration
registration = Task.find_or_initialize_by(name: "Registration (Anmeldung)", city: munich)
registration.update!(
  pillar:         pillar_housing,
  category:       "housing_and_registration",
  description:    "Register your address with the local authorities to obtain your Meldebescheinigung.",
  why_it_matters: "Without registration you cannot open a bank account, get health insurance, or receive official mail. It is legally required within 14 days of moving in.",
  urgency:        "high"
)

# Pillar 3 — Finance & Banking
banking = Task.find_or_initialize_by(name: "Banking", city: munich)
banking.update!(
  pillar:         pillar_finance,
  category:       "finance_and_banking",
  description:    "Open a German bank account to receive your salary and pay bills locally.",
  why_it_matters: "Most German employers require a local IBAN to process payroll. Without it your first salary payment may be delayed.",
  urgency:        "medium"
)

# Pillar 4 — Health & Insurance
health = Task.find_or_initialize_by(name: "Health Insurance", city: munich)
health.update!(
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Apply for the mandatory state health insurance subsidy to reduce your monthly premiums before the deadline.",
  why_it_matters: "As an expat, choosing the right public health insurance ensures your dependents are covered at no extra cost. Securing this subsidy promptly prevents you from being placed on a default, higher-premium plan.",
  urgency:        "medium"
)

puts "Tasks seeded: #{Task.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# SUBTASKS  (ChecklistItems per Main Task)
# ─────────────────────────────────────────────────────────────────────────────

# Pillar 2, Task 1 — Registration (Anmeldung): 6 structured subtasks
# Destroy old items + their dependent chats first (FK constraint on chats table)
old_item_ids = ChecklistItem.where(task: registration).pluck(:id)
Chat.where(checklist_item_id: old_item_ids).destroy_all
ChecklistItem.where(task: registration).destroy_all

registration_steps = [
  {
    position:              1,
    title:                 "Get landlord confirmation (Wohnungsgeberbestätigung)",
    description:           "Ask your landlord to fill and sign the official Wohnungsgeberbestätigung form. A standard rental contract is no longer legally sufficient for the Anmeldung.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Gather identity documents",
    description:           "Prepare your valid passport or national ID. Non-EU citizens must also bring the original visa or electronic residence permit (eAT).",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Prepare civil status certificates + translations (if applicable)",
    description:           "If you were married or had children abroad, bring original marriage/birth certificates. If not in CIEC multilingual format, a certified translation by a German sworn translator is required — an apostille may also be needed.",
    category:              "housing_and_registration",
    is_optional:           true,   # Optional badge — only needed for some users
    unlock_after_position: nil
  },
  {
    position:              4,
    title:                 "Book Bürgerbüro appointment",
    description:           "Book your Anmeldung appointment online at the Munich Bürgerbüro (KVR). Slots fill quickly — book as soon as you have your Wohnungsgeberbestätigung.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: 2   # Soft-locked: recommended after Steps 1 & 2 are done
  },
  {
    position:              5,
    title:                 "Attend appointment & collect Meldebescheinigung",
    description:           "Attend your Bürgerbüro appointment in person — all documents must be presented as originals, not scanned copies. You will receive your Meldebescheinigung on the spot.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: 4   # Soft-locked: only sensible after appointment is booked (Step 4)
  },
  {
    position:              6,
    title:                 "Prepare Vollmacht (Power of Attorney) if sending someone else",
    description:           "If you cannot attend the appointment in person, prepare and sign a Vollmacht (Power of Attorney) for the person attending on your behalf. Must be an original signature.",
    category:              "housing_and_registration",
    is_optional:           true,  # Optional badge — only needed if user cannot attend
    unlock_after_position: nil
  }
]

registration_steps.each do |attrs|
  ChecklistItem.create!(task: registration, **attrs)
end


# Banking subtasks
ChecklistItem.find_or_create_by!(title: "Open a German bank account", task: banking) do |item|
  item.category = "finance_and_banking"
end

ChecklistItem.find_or_create_by!(title: "Set up online banking", task: banking) do |item|
  item.category = "finance_and_banking"
end

# ─────────────────────────────────────────────────────────────────────────────
# Pillar 2, Task 2 — Set Up Household Utilities
# ─────────────────────────────────────────────────────────────────────────────
household = Task.find_or_initialize_by(name: "Set Up Household Utilities", city: munich)
household.update!(
  pillar:         pillar_housing,
  category:       "housing_and_registration",
  description:    "Register for the broadcasting fee, set up your electricity contract, and arrange your internet connection.",
  why_it_matters: "The Rundfunkbeitrag is legally mandatory for every household. Signing your own electricity contract prevents you from being billed at the expensive default SWM Grundversorgung tariff.",
  urgency:        "medium"
)

household_steps = [
  {
    position:              1,
    title:                 "Register for broadcasting fee (Rundfunkbeitrag)",
    description:           "Register your household with ARD ZDF Deutschlandradio Beitragsservice to pay the €18.36/month broadcasting fee. In shared flats (WGs), ask the main tenant for their Beitragsnummer — you can be added as a co-occupant instead of creating a new account.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Set up electricity contract",
    description:           "Sign up with a private electricity provider to avoid the expensive SWM Grundversorgung default tariff. You will need your meter reading (Zählerstand) and meter number (Zählernummer) from move-in day.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Set up internet/broadband contract",
    description:           "Sign a broadband internet contract with a provider such as Deutsche Telekom, Vodafone, or O2. You will need your passport and IBAN. Lead times can be 2–4 weeks — book early.",
    category:              "housing_and_registration",
    is_optional:           false,
    unlock_after_position: nil
  }
]

household_steps.each do |attrs|
  ChecklistItem.create!(task: household, **attrs)
end

# =============================================================================
# PILLAR 4 — HEALTH & INSURANCE
# 5 Main Tasks, each representing a distinct insurance category.
# No soft-lock (unlock_after_position: nil everywhere).
# is_optional: true = Optional badge shown in UI.
# =============================================================================

# ── Task 1: Health Insurance (Krankenversicherung) ───────────────────────────
# Rename existing record in-place to preserve Task ID + any user progress.
health.update!(
  name:           "Health Insurance (Krankenversicherung)",
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Choose between public (GKV) and private (PKV) health insurance and complete your enrolment before starting work.",
  why_it_matters: "Health insurance is legally required for everyone in Germany. Registering with a GKV automatically triggers your lifelong Sozialversicherungsnummer, which your employer needs for payroll.",
  urgency:        "high"
)

# Destroy old stubs (and their linked chats) before rebuilding
old_health_ids = ChecklistItem.where(task: health).pluck(:id)
Chat.where(checklist_item_id: old_health_ids).destroy_all
ChecklistItem.where(task: health).destroy_all

health_steps = [
  {
    position:              1,
    title:                 "Get temporary Expat health insurance (if arriving before job start)",
    description:           "If you arrive in Germany before your employment begins, you need a temporary Expat or incoming health insurance policy. Local statutory health funds (GKV) typically cannot enrol you until you have a German employment contract.",
    category:              "health_and_insurance",
    is_optional:           true,    # Only needed if there is a gap before employment starts
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Determine GKV vs PKV eligibility",
    description:           "Check whether your gross annual salary exceeds the Versicherungspflichtgrenze (€77,400 in 2026). If yes, you may opt for private health insurance (PKV). If no, you are required to join a statutory fund (GKV). Freelancers and civil servants may also choose PKV regardless of income.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Gather required documents",
    description:           "Prepare: valid passport, Meldebescheinigung (registration certificate), employment contract or salary statement, and — if moving from another EU country — the E104 form from your previous insurer to ensure seamless GKV enrolment.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              4,
    title:                 "Choose your health insurance provider",
    description:           "For GKV, compare funds such as TK (Techniker Krankenkasse), AOK Bayern, Barmer, or DAK. All charge the same base rate (14.6% of gross salary) but differ in additional services and English-language support. For PKV, obtain quotes from at least 3 providers — premiums vary by age and health status.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              5,
    title:                 "Submit application and enrol",
    description:           "Complete the insurer's registration form and submit your documents. For GKV, most funds offer an online application. You will receive a membership confirmation letter, which you must forward to your employer's HR department.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              6,
    title:                 "Submit passport photo for electronic health card (eGK)",
    description:           "Most GKV funds (TK, AOK, Barmer) allow you to upload a passport photo via their app. The eGK will be sent to your registered address within 2–4 weeks and is required to access doctors and pharmacies.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              7,
    title:                 "Obtain Sozialversicherungsnummer and share with employer",
    description:           "Your GKV enrolment automatically triggers the issuance of your permanent Sozialversicherungsnummer (social security number). Once received (by post), forward it to HR — it is required for legal payroll processing.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              8,
    title:                 "Request E104 form from previous EU insurer (if applicable)",
    description:           "If you were previously insured in another EU/EEA country, request the E104 form from your old insurer. This document confirms your insurance history and allows seamless acceptance into a German GKV without waiting periods.",
    category:              "health_and_insurance",
    is_optional:           true,    # Only relevant for EU movers with prior statutory insurance
    unlock_after_position: nil
  }
]

health_steps.each { |attrs| ChecklistItem.create!(task: health, **attrs) }

# ── Task 2: Personal Liability Insurance (Privathaftpflicht) ─────────────────
haftpflicht = Task.find_or_initialize_by(name: "Personal Liability Insurance (Privathaftpflicht)", city: munich)
haftpflicht.update!(
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Get covered for accidental damage you cause to other people or property — from a broken smartphone to a flooded neighbour's flat.",
  why_it_matters: "Not legally required, but culturally non-negotiable in Germany. Losing a building's key can cost €5,000+ for lock replacement. Without Haftpflicht, you are personally liable for the full amount. Costs as little as €40–60/year for a single person.",
  urgency:        "high"
)

old_ids = ChecklistItem.where(task: haftpflicht).pluck(:id)
Chat.where(checklist_item_id: old_ids).destroy_all
ChecklistItem.where(task: haftpflicht).destroy_all

haftpflicht_steps = [
  {
    position:              1,
    title:                 "Understand what to look for in a policy",
    description:           "A good Privathaftpflicht policy for expats in Munich should include: Schlüsselverlust (key loss), Mietsachschäden (rental damage), Forderungsausfalldeckung (protection if an uninsured third party injures you), grobe Fahrlässigkeit (gross negligence), and Gefälligkeitshandlungen (damage while helping friends).",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Compare providers and choose a policy",
    description:           "Use a comparison tool (Check24, Verivox, or Clark) to compare policies. Ensure all required clauses are included. Singles pay approx. €40–60/year; families €70–120/year. Providers like DEVK, Huk24, or Getsafe offer English-friendly onboarding.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Sign up online and save your policy document",
    description:           "Complete the application online — you will need your name, address, and date of birth. Download and store your Versicherungsschein (policy document) in a safe place. Coverage typically begins the same day.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  }
]

haftpflicht_steps.each { |attrs| ChecklistItem.create!(task: haftpflicht, **attrs) }

# ── Task 3: Home Contents Insurance (Hausratversicherung) ────────────────────
hausrat = Task.find_or_initialize_by(name: "Home Contents Insurance (Hausratversicherung)", city: munich)
hausrat.update!(
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Protect your personal belongings — furniture, electronics, clothing — against fire, water damage, storm, and burglary.",
  why_it_matters: "A simple rule: everything that would fall out if you turned your flat upside down is your Hausrat. Replacing stolen or fire-damaged belongings without insurance can cost tens of thousands of euros.",
  urgency:        "medium"
)

old_ids = ChecklistItem.where(task: hausrat).pluck(:id)
Chat.where(checklist_item_id: old_ids).destroy_all
ChecklistItem.where(task: hausrat).destroy_all

hausrat_steps = [
  {
    position:              1,
    title:                 "Calculate the right coverage amount",
    description:           "German Hausrat policies are priced per square metre. Find your apartment's floor area in your rental contract (Mietvertrag) and use it as the coverage basis. The standard rule is €650–700 of coverage per m². Keep purchase receipts for expensive items.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Choose a policy — ensure bicycle theft add-on is included",
    description:           "Bicycle theft is extremely common in Munich and Berlin. When comparing policies, specifically look for the 'Fahrraddiebstahl' add-on and check that there is no Nachtklausel (night clause) excluding thefts between 22:00–06:00. Recommended providers: Getsafe, ARAG, Allianz.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Sign up and store your policy documents",
    description:           "Complete the application with your address and floor area. Store the Versicherungsschein digitally and note the claims hotline number — it will be needed immediately in case of a burglary or water damage.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  }
]

hausrat_steps.each { |attrs| ChecklistItem.create!(task: hausrat, **attrs) }

# ── Task 4: Disability Insurance (Berufsunfähigkeitsversicherung) ─────────────
bu = Task.find_or_initialize_by(name: "Disability Insurance (Berufsunfähigkeitsversicherung)", city: munich)
bu.update!(
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Secure a monthly income replacement if you become unable to work due to illness, accident, or burnout for more than 6 months.",
  why_it_matters: "The German state pays very little in disability benefits — especially for those who have not contributed long enough. Freelancers, sole earners, and anyone with a mortgage are most at risk without BU coverage.",
  urgency:        "medium"
)

old_ids = ChecklistItem.where(task: bu).pluck(:id)
Chat.where(checklist_item_id: old_ids).destroy_all
ChecklistItem.where(task: bu).destroy_all

bu_steps = [
  {
    position:              1,
    title:                 "Assess your personal need",
    description:           "BU is most critical for: freelancers and self-employed (no employer sick-pay), sole earners supporting a family, people with a mortgage, and those in physically or mentally demanding jobs. If you have significant savings or a working partner, your need may be lower.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Get independent advice before signing",
    description:           "BU policies are complex. Avoid signing without independent advice. Contact a Verbraucherzentrale (consumer advice centre) or an independent fee-based broker (Honorarberater). The key policy clause to check: 'abstrakte Verweisung' — ensure your policy does NOT include this clause (it would allow the insurer to point you to any other job instead of paying out).",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Compare policies and sign",
    description:           "Compare at least 3 quotes. Ensure the payout amount covers your monthly living costs. Typical monthly benefit: 60–80% of your net income. The younger and healthier you are when you sign, the lower the premium — do not delay.",
    category:              "health_and_insurance",
    is_optional:           false,
    unlock_after_position: nil
  }
]

bu_steps.each { |attrs| ChecklistItem.create!(task: bu, **attrs) }

# ── Task 5: Supplementary Insurance ─────────────────────────────────────────
supplementary = Task.find_or_initialize_by(name: "Supplementary Insurance", city: munich)
supplementary.update!(
  pillar:         pillar_health,
  category:       "health_and_insurance",
  description:    "Depending on your lifestyle and situation, review these additional insurance types — some may be legally required for you.",
  why_it_matters: "Germany has a complex legal and rental landscape. Some supplementary insurances are mandatory in certain states or situations (dogs in Berlin, cars anywhere in Germany), while others prevent major unexpected costs.",
  urgency:        "low"
)

old_ids = ChecklistItem.where(task: supplementary).pluck(:id)
Chat.where(checklist_item_id: old_ids).destroy_all
ChecklistItem.where(task: supplementary).destroy_all

supplementary_steps = [
  {
    position:              1,
    title:                 "Legal protection insurance (Rechtsschutzversicherung)",
    description:           "Covers lawyer and court fees in disputes with your landlord (e.g. deposit disputes), employer, or public authorities. Particularly relevant in Germany given the complex tenant and employment law. Costs approx. €100–200/year.",
    category:              "health_and_insurance",
    is_optional:           true,
    unlock_after_position: nil
  },
  {
    position:              2,
    title:                 "Dental add-on insurance (Zahnzusatzversicherung)",
    description:           "The statutory GKV only covers basic 'Regelversorgung' dental treatments. For crowns, implants, professional cleaning (PZR), or high-quality fillings, a Zahnzusatzversicherung prevents large out-of-pocket costs. Recommended if you value your dental health.",
    category:              "health_and_insurance",
    is_optional:           true,
    unlock_after_position: nil
  },
  {
    position:              3,
    title:                 "Dog liability insurance (Tierhalterhaftpflicht) — mandatory if you own a dog",
    description:           "If you bring a dog to Germany, Tierhalterhaftpflicht is legally mandatory in Bavaria, Berlin, Hamburg, and other states. It covers personal injury and property damage caused by your dog. Sign up immediately upon arriving with a dog.",
    category:              "health_and_insurance",
    is_optional:           true,
    unlock_after_position: nil
  },
  {
    position:              4,
    title:                 "Car insurance (Kfz-Haftpflicht) — mandatory if you own a car",
    description:           "If you own or register a vehicle in Germany, Kfz-Haftpflicht (third-party car liability) is legally required. You cannot register a car without it. Teilkasko (partial coverage) and Vollkasko (full coverage) are optional add-ons but recommended for newer vehicles.",
    category:              "health_and_insurance",
    is_optional:           true,
    unlock_after_position: nil
  }
]

supplementary_steps.each { |attrs| ChecklistItem.create!(task: supplementary, **attrs) }

puts "Subtasks seeded: #{ChecklistItem.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# DEV USER  (development only)
# ─────────────────────────────────────────────────────────────────────────────
User.find_or_create_by!(email: "dev@landed.com") do |u|
  u.password              = "password"
  u.password_confirmation = "password"
end

puts "Seeds complete. #{DocumentType.count} document types | #{Pillar.count} pillars | #{Task.count} tasks | #{ChecklistItem.count} subtasks."

