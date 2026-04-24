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
registration = Task.find_or_create_by!(name: "Registration (Anmeldung)", city: munich)
banking = Task.find_or_create_by!(name: "Banking", city: munich)
health = Task.find_or_create_by!(name: "Health Insurance", city: munich)

ChecklistItem.find_or_create_by!(title: "Book Anmeldung appointment", task: registration) { |item| item.category = "Admin" }
ChecklistItem.find_or_create_by!(title: "Gather required documents for Anmeldung", task: registration) { |item| item.category = "Admin" }
ChecklistItem.find_or_create_by!(title: "Attend appointment and collect Meldebescheinigung", task: registration) { |item| item.category = "Admin" }

ChecklistItem.find_or_create_by!(title: "Open a German bank account", task: banking) { |item| item.category = "Finance" }
ChecklistItem.find_or_create_by!(title: "Set up online banking", task: banking) { |item| item.category = "Finance" }

ChecklistItem.find_or_create_by!(title: "Choose public or private health insurance", task: health) { |item| item.category = "Admin" }
ChecklistItem.find_or_create_by!(title: "Submit health insurance registration", task: health) { |item| item.category = "Admin" }

# User for testing
dev_user = User.find_or_create_by!(email: "dev@landed.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

# Mid-Term Presentation Seed: Housing & Registration (Munich) Document
puts "Seeding presentation document..."
pdf_url = "https://stadt.muenchen.de/dam/jcr:15cee8cc-bd9a-46f0-9c4b-052766dc547f/Anmeldung_Meldeschein_20220622.pdf"

chat = Chat.new(
  title:         "Registration Form (Meldeschein)",
  document_type: "Housing & Registration",
  amount:        0.00,
  deadline:      Date.new(2023, 10, 9),
  advice:        "This document is a registration form that individuals must fill out when moving to a new residence in Germany. It captures personal details such as name, address, and previous residence. You need to submit it to the local authorities to officially register your new address. Make sure to provide all required information accurately.",
  urgency:       "medium",
  is_mandatory:  true,
  user:          dev_user,
  checklist_item: ChecklistItem.find_by(title: "Gather required documents for Anmeldung")
)

begin
  chat.document.attach(
    io: URI.open(pdf_url),
    filename: 'Anmeldung_Meldeschein_20220622.pdf',
    content_type: 'application/pdf'
  )
  if chat.save
    puts "Successfully seeded presentation document (Chat ID: #{chat.id})"
  else
    puts "FAILED to seed chat: #{chat.errors.full_messages}"
  end
rescue => e
  puts "FAILED to download or attach PDF: #{e.message}"
end
