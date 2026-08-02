require "net/http"

class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item, optional: true
  has_many :messages, dependent: :destroy
  belongs_to :provider, optional: true

  has_one_attached :document do |attachable|
    attachable.variant :ai_ready, resize_to_limit: [2048, 2048], format: :jpeg, saver: { quality: 85 }
  end

  def ask_document(question)
    return "No document context available." unless advice.present?

    begin
      response = call_anthropic(qa_settings(question))
      raw_text = response.dig("content", 0, "text")
      raw_text || "I could not generate a response."
    rescue => e
      Rails.logger.error "Chat Q&A Failed: #{e.message}"
      "Something went wrong. Please try again."
    end
  end

  def analyze_document
    return unless document.attached?
    return unless document.content_type.start_with?("image/") || document.content_type == "application/pdf"

    begin
      response = call_anthropic(ai_settings)
      raw_text = response.dig("content", 0, "text")
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
    adv          = parsed_advice
    summary      = adv.dig("summary") || ""
    explanation  = adv.dig("explanation") || ""
    facts        = adv.dig("key_facts")&.map { |f| f["text"] }&.join(" ") || ""
    contact      = adv.dig("contact_info")
    contact_text = contact.present? ? "Contact information: #{contact}." : ""
    advice_text  = "#{summary} #{explanation} #{facts} #{contact_text}".strip.presence || advice.to_s

    {
      model: "claude-haiku-4-5",
      max_tokens: 500,
      system: "You are a helpful assistant that answers questions about German bureaucracy documents. " \
              "You have already analyzed: \"#{title}\" (#{document_type}). " \
              "Here is what the document means: #{advice_text} " \
              "Answer the user's question in plain English. Be concise and direct. " \
              "If the detail genuinely isn't covered above, say so plainly rather than guessing.",
      messages: [
        {
          role: "user",
          content: question
        }
      ]
    }
  end

  def call_anthropic(body)
    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"
    request.body = body.to_json

    response = http.request(request)
    unless response.code.start_with?("2")
      Rails.logger.error "Anthropic API error (#{response.code}): #{response.body}"
    end
    JSON.parse(response.body)
  end

  def analysis_prompt
    <<~PROMPT
      Today's date is #{Date.today.strftime("%Y-%m-%d")}.

      Analyze this document and return ONLY a JSON object with these keys:
      1. 'title' (English with German in brackets)
      2. 'amount' (Float)
      3. 'deadline' (YYYY-MM-DD)
      4. 'urgency' (high, medium, low) — set to 'high' if the deadline (if any) is today or has already passed relative to today's date above
      5. 'document_type' — a SHORT category label, maximum 2 words, no slashes, no compound phrases (e.g. 'Krankenkasse', 'Finanzamt', 'Utility Bill', 'Tax Notice'). Never combine two category names with a slash.
      6. 'advice' as a nested object with:
         - 'summary': one plain-English action sentence telling the user what they need to do — not a document definition, not a description, but a direct action prompt (e.g. 'You need to submit this form to confirm your address with the Munich authorities.'). If the deadline has already passed relative to today's date, say so plainly here and stress urgency.
         - 'explanation': write 3-4 sentences directly to the user as if you are a knowledgeable friend helping them navigate German bureaucracy. Be warm, specific, and reassuring. Tell them what this document means for their situation, what they should do next, and what to watch out for. Use you and your throughout. Never be generic. If the deadline has already passed relative to today's date, acknowledge that clearly and explain what to do next given that it's overdue. Wrap every concrete number, amount, or date that appears in this sentence in double asterisks, e.g. "You owe **€194.78** by **February 12, 2026**." Do this for every such value, not just the first one.
         - 'stats': array of up to 4 objects, each with 'label', 'value', 'sub', and optional 'highlight' (warn or critical). The value must be short — maximum 3 words, no sentences. Always prioritise these categories in this order if present in the document: amount or fee owed, deadline or due date, penalty for missing deadline, contest or appeal window. Only use other categories if none of these apply. Labels must be short and clear in plain English — never use German institution names as a value. Always format currency values with the euro symbol before the number with no space (e.g. the symbol comes first, then the digits).
         - 'key_facts': array of 3 objects with 'n' (1,2,3) and 'text' (warm and friendly, written directly to the user using you and your, like helping a friend navigate German bureaucracy — be reassuring and practical, not robotic). Wrap every concrete number, amount, or date in double asterisks the same way as in 'explanation'.
         - 'contact_info': any phone number, email address, or physical office address found in the document for contacting the issuing authority or customer service. Combine all found details into one short plain-text string (e.g. "Phone: +49 38203 713-0, Email: service@zvk-dbr.de, Mon-Thu 7:00-17:00, Fri 7:00-15:00"). Use null if genuinely no contact details appear anywhere in the document.
         - 'regions': array of objects identifying which section of the document contains each key value. Each object must have: 'field' (one of: deadline, amount, recipient_name, reference_number), 'label' (short display label e.g. 'Fee', 'Deadline'), 'y' (top edge of the section as % of image height — start exactly at the section header line, e.g. the line that reads 'Gebühr', not the element above it), 'h' (height of a single line as % of image height — typically 2-3%, never more than 4%). 'y' must point to the exact line containing the printed value, not the section header above it. Always span the full width: 'x' is always 0, 'w' is always 100. If you cannot locate the exact line with confidence, omit that region entirely.
         - 'Never start a fact with "It\'s" or "This". Every fact must open with "You", "Your", or "Make sure you".'
         PROMPT
  end

  def ai_settings
    {
      model: "claude-haiku-4-5",
      max_tokens: 1600,
      system: "You are a German admin expert. Extract data AND identify the document type " \
              "so we can match it against our internal bureaucracy guide. " \
              "You MUST return ONLY a valid JSON object. No markdown, no explanation.",
      messages: [
        {
          role: "user",
          content: [
            content_block,
            {
              type: "text",
              text: analysis_prompt
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
        type: "image",
        source: {
          type: "base64",
          media_type: document.content_type,
          data: encoded_file
        }
      }
    end
  end

  def encoded_file
    Base64.strict_encode64(document.download)
  end

  def extract_pdf_text
    require "pdf-reader"
    reader = PDF::Reader.new(StringIO.new(document.download))
    reader.pages.map.with_index(1) do |page, i|
      "--- Page #{i} ---\n#{page.text}"
    end.join("\n")
  rescue => e
    Rails.logger.error "PDF extraction failed: #{e.message}"
    "Could not extract text from PDF."
  end
end
