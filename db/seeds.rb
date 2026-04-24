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


# Dev user for testing (development only)
dev_user = User.find_or_create_by!(email: "dev@landed.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

puts "Seeds complete. #{DocumentType.count} document types ready for matching."

