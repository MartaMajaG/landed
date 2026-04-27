require 'open-uri'

# Cities
berlin = City.find_or_create_by!(name: "Berlin", country: "Germany")
munich = City.find_or_create_by!(name: "Munich", country: "Germany")
hamburg = City.find_or_create_by!(name: "Hamburg", country: "Germany")

puts "Cities seeded."

# Document Types Knowledge Base
puts "Seeding Document Types..."
doc_types_path = Rails.root.join('db', 'seeds', 'data', 'document_types.json')
doc_types_data = JSON.parse(File.read(doc_types_path))

doc_types_data.each do |data|
  DocumentType.find_or_create_by!(slug: data['id']) do |dt|
    dt.name = data['name']
    dt.master_data = data
  end
end
puts "Seeding complete: #{DocumentType.count} document types loaded."

# Tasks & Checklists
# registration = Task.find_or_create_by!(name: "Registration (Anmeldung)", city: munich) do |t|
#   t.category = "Admin"
#   t.description = "Register your address with the local authorities to obtain your Meldebescheinigung."
#   t.why_it_matters = "Without registration you cannot open a bank account, get health insurance, or receive official mail. It is legally required within 14 days of moving in."
#   t.urgency = "high"
# end
registration = Task.find_or_initialize_by(name: "Registration (Anmeldung)", city: munich)
registration.update!(
  category: "Admin",
  description: "Register your address with the local authorities to obtain your Meldebescheinigung.",
  why_it_matters: "Without registration you cannot open a bank account, get health insurance, or receive official mail. It is legally required within 14 days of moving in.",
  urgency: "high"
)

# banking = Task.find_or_create_by!(name: "Banking", city: munich) do |t|
#   t.category = "Finance"
#   t.description = "Open a German bank account to receive your salary and pay bills locally."
#   t.why_it_matters = "Most German employers require a local IBAN to process payroll. Without it your first salary payment may be delayed."
#   t.urgency = "medium"
# end
#
banking = Task.find_or_initialize_by(name: "Banking", city: munich)
banking.update!(
  category: "Finance",
  description: "Open a German bank account to receive your salary and pay bills locally.",
  why_it_matters: "Most German employers require a local IBAN to process payroll. Without it your first salary payment may be delayed.",
  urgency: "medium"
)

# health = Task.find_or_create_by!(name: "Health Insurance", city: munich) do |t|
#   t.category = "Health Insurance"
#   t.description = "Apply for the mandatory state health insurance"
#   t.urgency = "medium"
# end

health = Task.find_or_initialize_by(name: "Health Insurance", city: munich)
health.update!(
  category: "Health Insurance",
  description: "Apply for the mandatory state health insurance",
  urgency: "low"
)

ChecklistItem.find_or_create_by!(title: "Book Anmeldung appointment", task_id: 1) { |item| item.category = "Admin" }
ChecklistItem.find_or_create_by!(title: "Gather required documents for Anmeldung", task_id: 1) { |item| item.category = "Admin" }
ChecklistItem.find_or_create_by!(title: "Attend appointment and collect Meldebescheinigung", task_id: 1) { |item| item.category = "Admin" }

ChecklistItem.find_or_create_by!(title: "Open a German bank account", task_id: 2) { |item| item.category = "Finance" }
ChecklistItem.find_or_create_by!(title: "Set up online banking", task_id: 2) { |item| item.category = "Finance" }

ChecklistItem.find_or_create_by!(title: "Choose public or private health insurance", task_id: 3) do |item|
  item.category = "Admin"
  item.description = "Compare public health insurance providers and submit your application along with your employment contract."
end

ChecklistItem.find_or_create_by!(title: "Submit health insurance registration", task_id: 3) do |item|
  item.category = "Admin"
  item.description = "Submit your completed application to your chosen provider and forward confirmation to your employer."
end

# Dev user for testing (development only)
dev_user = User.find_or_create_by!(email: "dev@landed.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

puts "Seeds complete. #{DocumentType.count} document types ready for matching."
