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

ChecklistItem.find_or_create_by!(title: "Register Residence Address", task: health) do |item|
  item.category    = "health_and_insurance"
  item.description = "Register your address at the local Bürgeramt to obtain your Meldebescheinigung."
end

ChecklistItem.find_or_create_by!(title: "Choose public or private health insurance", task: health) do |item|
  item.category    = "health_and_insurance"
  item.description = "Compare public health insurance providers and submit your application along with your employment contract."
end

ChecklistItem.find_or_create_by!(title: "Submit health insurance registration", task: health) do |item|
  item.category    = "health_and_insurance"
  item.description = "Submit your completed application to your chosen provider and forward confirmation to your employer."
end

ChecklistItem.find_or_create_by!(title: "Submit Confirmation to Employer", task: health) do |item|
  item.category    = "health_and_insurance"
  item.description = "Forward your insurance confirmation letter to HR so they can process your payroll deductions."
end

puts "Subtasks seeded: #{ChecklistItem.count} total."

# ─────────────────────────────────────────────────────────────────────────────
# DEV USER  (development only)
# ─────────────────────────────────────────────────────────────────────────────
User.find_or_create_by!(email: "dev@landed.com") do |u|
  u.password              = "password"
  u.password_confirmation = "password"
end

puts "Seeds complete. #{DocumentType.count} document types | #{Pillar.count} pillars | #{Task.count} tasks | #{ChecklistItem.count} subtasks."

