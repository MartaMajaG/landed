require "net/http"

class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item, optional: true
  has_many :messages, dependent: :destroy

  has_one_attached :document do |attachable|
    attachable.variant :ai_ready, resize_to_limit: [2048, 2048], format: :jpeg, saver: { quality: 85 }
  end

  def ask_document(question)
    return "No document context available." unless advice.present?

    begin
      uri = URI("https://models.inference.ai.azure.com/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
      request.body = qa_settings(question).to_json

      response = http.request(request)
      parsed = JSON.parse(response.body)
      parsed.dig("choices", 0, "message", "content") || "I could not generate a response."
    rescue => e
      Rails.logger.error "Chat Q&A Failed: #{e.message}"
      "Something went wrong. Please try again."
    end
  end

  def analyze_document
    return unless document.attached?
    return unless document.content_type.start_with?("image/") || document.content_type == "application/pdf"

    begin
      response = call_github_models
      raw_text = response.dig("choices", 0, "message", "content")
      parsed = JSON.parse(raw_text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip)
      parsed["advice"] = parsed["advice"].to_json if parsed["advice"].is_a?(Hash)
      parsed
    rescue => e
      Rails.logger.error "Chat AI Analysis Failed: #{e.message}"
      { "title" => "Manual Review Required", "urgency" => "medium" }
    end
  end

  def parsed_advice
    return {} unless advice.present?
    begin
      advice.is_a?(Hash) ? advice : JSON.parse(advice)
    rescue JSON::ParserError
      { "summary" => advice.to_s }
    end
  end

  private

  def qa_settings(question)
    adv         = parsed_advice
    summary     = adv.dig("summary") || ""
    explanation = adv.dig("explanation") || ""
    facts       = adv.dig("key_facts")&.map { |f| f["text"] }&.join(" ") || ""
    advice_text = "#{summary} #{explanation} #{facts}".strip.presence || advice.to_s

    {
      model: "gpt-4o-mini",
      max_tokens: 500,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant that answers questions about German bureaucracy documents. " \
                   "You have already analyzed: \"#{title}\" (#{document_type}). " \
                   "Here is what the document means: #{advice_text} " \
                   "Answer the user's question in plain English. Be concise and direct."
        },
        {
          role: "user",
          content: question
        }
      ]
    }
  end

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

  def ai_settings
    {
      model: "gpt-4o-mini",
      max_tokens: 1200,
      messages: [
        {
          role: "system",
          content: "You are a German admin expert. Extract data AND identify the document type " \
                   "so we can match it against our internal bureaucracy guide. " \
                   "You MUST return ONLY a valid JSON object. No markdown, no explanation."
        },
        {
          role: "user",
          content: [
            content_block,
            {
              type: "text",
              text: "Analyze this document and return ONLY a JSON object with these keys:
                     1. 'title' (English with German in brackets)
                     2. 'amount' (Float)
                     3. 'deadline' (YYYY-MM-DD)
                     4. 'urgency' (high, medium, low)
                     5. 'document_type' (e.g., 'Krankenkasse', 'Finanzamt', 'Steuer')
                     6. 'advice' as a nested object with:
                        - 'summary': one plain-English action sentence telling the user what they need to do — not a document definition, not a description, but a direct action prompt (e.g. 'You need to submit this form to confirm your address with the Munich authorities.')
                        - 'explanation': write 3-4 sentences directly to the user as if you are a knowledgeable friend helping them navigate German bureaucracy. Be warm, specific, and reassuring. Tell them what this document means for their situation, what they should do next, and what to watch out for. Use you and your throughout. Never be generic.
                        - 'stats': array of up to 4 objects, each with 'label', 'value', 'sub', and optional 'highlight' (warn or critical). The value must be short — maximum 3 words, no sentences. Always prioritise these categories in this order if present in the document: amount or fee owed, deadline or due date, penalty for missing deadline, contest or appeal window. Only use other categories if none of these apply. Labels must be short and clear in plain English — never use German institution names as a value. Always format currency values with the euro symbol before the number with no space (e.g. the symbol comes first, then the digits).
                        - 'key_facts': array of 3 objects with 'n' (1,2,3) and 'text' (warm and friendly, written directly to the user using you and your, like helping a friend navigate German bureaucracy — be reassuring and practical, not robotic)"
            }
          ]
        }
      ]
    }
  end

  def content_block
    if document.content_type == "application/pdf"
      {
        type: "text",
        text: "Note: this is a PDF document. Extracted content: #{extract_pdf_text}"
      }
    else
      {
        type: "image_url",
        image_url: {
          url: "data:#{document.content_type};base64,#{encoded_file}"
        }
      }
    end
  end

  def encoded_file
    Base64.strict_encode64(document.download)
  end

  def extract_pdf_text
    reader = PDF::Reader.new(StringIO.new(document.download))
    reader.pages.map.with_index(1) do |page, i|
      "--- Page #{i} ---\n#{page.text}"
    end.join("\n")
  rescue => e
    Rails.logger.error "PDF extraction failed: #{e.message}"
    "Could not extract text from PDF."
  end
end
