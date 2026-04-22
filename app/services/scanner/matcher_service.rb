module Scanner
  class MatcherService
    # Threshold: At least one marker must be found to consider a match valid
    CONFIDENCE_THRESHOLD = 1

    def initialize(extracted_text)
      @text = extracted_text.to_s.downcase
    end

    def call
      best_match = nil
      max_score = 0

      # We iterate through all document types in the Knowledge Base
      DocumentType.all.each do |type|
        score = calculate_score(type)

        if score > max_score && score >= CONFIDENCE_THRESHOLD
          max_score = score
          best_match = type
        end
      end

      # Return a hash with the match results and the original research logic
      {
        matched_type: best_match,
        confidence_score: max_score,
        target_logic: best_match&.master_data&.dig('logic') || {}
      }
    end

    private

    def calculate_score(document_type)
      score = 0
      markers = document_type.detection_markers

      # We increment the score for each keyword found in the text
      markers.each do |marker|
        score += 1 if @text.include?(marker.downcase)
      end

      score
    end
  end
end
