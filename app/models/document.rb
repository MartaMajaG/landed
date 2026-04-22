class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  def extract_ai_data
    begin
      response = client.messages.create(parameters: anthropic_settings)
      raw_text = response.dig("content", 0, "text")
      JSON.parse(raw_text)
    rescue => e
      Rails.logger.error "Anthropic Scan Failed: #{e.message}"
      { "title" => "Manual Review Required", "urgency" => "medium" }
    end
  end

  private

  def client
    @client ||= Anthropic::Client.new
  end

def ai_instructions
    {
      model: "claude-3-5-sonnet-20240620",
      max_tokens: 1000,
      # Your System Persona: Setting the expertise
      system: "You are a German admin expert. Extract data AND identify the document type " \
              "so we can match it against our internal bureaucracy guide. " \
              "You MUST return ONLY a valid JSON object.",
      messages: [
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

  # This method decides if we are sending an "image" or a "document"
  def content_block
    if self.file.content_type == "application/pdf"
      {
        type: "document",
        source: {
          type: "base64",
          media_type: "application/pdf",
          data: encoded_file
        }
      }
    else
      {
        type: "image",
        source: {
          type: "base64",
          media_type: self.file.content_type, # This will be image/png or image/jpeg
          data: encoded_file
        }
      }
    end
  end
# encoded into base64 -> binary to string, then to hash to json (with anthropic gem)!!
  def encoded_file
    Base64.strict_encode64(self.file.download)
  end
end