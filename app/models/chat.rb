require "net/http"

class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item

  has_one_attached :document do |attachable|
    attachable.variant :ai_ready, resize_to_limit: [2048, 2048], format: :jpeg, saver: { quality: 85 }
  end

  # Sends the attached image to GitHub Models and returns extracted fields as a hash
  def analyze_document
    return unless document.attached?
    return unless document.content_type.start_with?("image/")

    begin
      response = call_github_models
      raw_text = response.dig("choices", 0, "message", "content")
      JSON.parse(raw_text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip)
    rescue => e
      Rails.logger.error "Chat AI Analysis Failed: #{e.message}"
      { "title" => "Manual Review Required", "urgency" => "medium" }
    end
  end

  private

  # Makes the HTTP POST request to GitHub Models and returns the parsed response body
  def call_github_models
    uri = URI("https://models.inference.ai.azure.com/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
    request.body = ai_settings.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end

  # Builds the payload sent to the AI: model, system persona, image, and extraction instructions
  def ai_settings
    {
      model: "gpt-4o-mini",
      max_tokens: 1000,
      messages: [
        {
          role: "system",
          content: "You are a German admin expert. Extract data AND identify the document type " \
                   "so we can match it against our internal bureaucracy guide. " \
                   "You MUST return ONLY a valid JSON object."
        },
        {
          role: "user",
          content: [
            content_block,
            {
              type: "text",
              text: "Please analyze this document and provide the following keys in JSON:
                     1. 'title' (English with German in brackets)
                     2. 'amount' (Float)
                     3. 'deadline' (YYYY-MM-DD)
                     4. 'urgency' (high, medium, low)
                     5. 'document_type' (e.g., 'Krankenkasse', 'Finanzamt', 'Steuer')
                     6. 'advice' (A clear explanation of the content in plain English for a newcomer)."
            }
          ]
        }
      ]
    }
  end

  # Wraps the image as a base64 data URL
  def content_block
    {
      type: "image_url",
      image_url: {
        url: "data:#{document.content_type};base64,#{encoded_file}"
      }
    }
  end

  # Downloads the file from Active Storage and encodes it to base64 for the API
  def encoded_file
    Base64.strict_encode64(document.download)
  end
end
