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

# Registration subtasks
ChecklistItem.find_or_create_by!(title: "Book Anmeldung appointment", task: registration) do |item|
  item.category = "housing_and_registration"
end

ChecklistItem.find_or_create_by!(title: "Gather required documents for Anmeldung", task: registration) do |item|
  item.category = "housing_and_registration"
end

ChecklistItem.find_or_create_by!(title: "Attend appointment and collect Meldebescheinigung", task: registration) do |item|
  item.category = "housing_and_registration"
end

# Banking subtasks
ChecklistItem.find_or_create_by!(title: "Open a German bank account", task: banking) do |item|
  item.category = "finance_and_banking"
end

ChecklistItem.find_or_create_by!(title: "Set up online banking", task: banking) do |item|
  item.category = "finance_and_banking"
end

# Health insurance subtasks
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

