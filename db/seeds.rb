<<<<<<< feature/LAN-7-scanner-foundation
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Master Data: Cities
["Berlin", "Munich", "Hamburg"].each do |city_name|
  City.find_or_create_by!(name: city_name, country: "Germany")
end

# Knowledge Base: Document Types for Scanner
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
=======
# seeds to test document uploader

berlin = City.find_or_create_by!(name: "Berlin", country: "Germany")
City.find_or_create_by!(name: "Munich", country: "Germany")
City.find_or_create_by!(name: "Hamburg", country: "Germany")

registration = Task.find_or_create_by!(name: "Registration (Anmeldung)", city: berlin)
banking = Task.find_or_create_by!(name: "Banking", city: berlin)
health = Task.find_or_create_by!(name: "Health Insurance", city: berlin)

ChecklistItem.find_or_create_by!(title: "Book Anmeldung appointment", task: registration) do |item|
  item.category = "Admin"
end
ChecklistItem.find_or_create_by!(title: "Gather required documents for Anmeldung", task: registration) do |item|
  item.category = "Admin"
end
ChecklistItem.find_or_create_by!(title: "Attend appointment and collect Meldebescheinigung", task: registration) do |item|
  item.category = "Admin"
end

ChecklistItem.find_or_create_by!(title: "Open a German bank account", task: banking) do |item|
  item.category = "Finance"
end
ChecklistItem.find_or_create_by!(title: "Set up online banking", task: banking) do |item|
  item.category = "Finance"
end

ChecklistItem.find_or_create_by!(title: "Choose public or private health insurance", task: health) do |item|
  item.category = "Admin"
end
ChecklistItem.find_or_create_by!(title: "Submit health insurance registration", task: health) do |item|
  item.category = "Admin"
end

# Dev user for testing
dev_user = User.find_by!(email: "dev@landed.com")

doc = Document.new(
  title:         "Anmeldung Confirmation",
  document_type: "Registration",
  amount:        0.00,
  deadline:      Date.today + 14.days,
  advice:        "Book your Bürgeramt appointment as soon as possible.",
  urgency:       "high"
)

if doc.save
  puts "Seeded document ID: #{doc.id}"
else
  puts "FAILED: #{doc.errors.full_messages}"
end
>>>>>>> master
