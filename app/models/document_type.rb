class DocumentType < ApplicationRecord
  # Extracts the array of detection markers from the JSONB master_data
  def detection_markers
    master_data["detection_markers"] || []
  end

  # Class method to find the best match for a given text
  def self.match(text)
    return { document_type: nil, score: 0 } if text.blank?

    normalized_text = text.to_s.downcase
    best_match = nil
    highest_score = 0

    find_each do |doc_type|
      score = doc_type.calculate_match_score(normalized_text)
      
      if score > highest_score
        highest_score = score
        best_match = doc_type
      end
    end

    {
      document_type: best_match,
      score: highest_score,
      target_logic: best_match&.master_data&.dig("logic") || {}
    }
  end

  # Instance method to calculate the score for a specific document type
  def calculate_match_score(text)
    score = 0
    markers = detection_markers
    
    return 0 if markers.empty?

    markers.each do |marker|
      if text.include?(marker.downcase)
        score += 1
      end
    end

    score
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
