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