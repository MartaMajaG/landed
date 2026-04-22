class DocumentType < ApplicationRecord
  # Validations to ensure data integrity in the Knowledge Base
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Ensuring master_data contains valid JSON structure
  validates :master_data, presence: true

  # Helper method to access category directly from the master_data
  def category
    master_data['category']
  end

  # Helper to retrieve detection markers for the Matcher Service
  def detection_markers
    master_data['detection_markers'] || []
  end
end
