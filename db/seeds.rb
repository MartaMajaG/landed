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
