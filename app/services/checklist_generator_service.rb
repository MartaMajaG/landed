require "net/http"
require "json"

class ChecklistGeneratorService
  API_URL = "https://models.inference.ai.azure.com/chat/completions"
  MODEL   = "gpt-4o-mini"
  SYSTEM_PROMPT = <<~PROMPT
    You are a german relocation expert helping expats settle in German cities.
    Generate step-by-step checklist items for a given relocation task.
    Return ONLY a valid JSON array. No markdown, no explanation, no preamble.
    Each item is an object with exactly two keys:
      - "title": short action phrase, max 8 words, sentence case, starts with a verb
      - "description": one sentence, max 20 words, explains what to do and why
    Generate between 3 and 6 steps depending on task complexity.
    Steps must be in logical order.
  PROMPT

  def initialize(task_name, city: "Munich")
    @task_name = task_name
    @city      = city
  end

  def call
    response = post_to_api
    parse_items(response)
  rescue StandardError => e
    Rails.logger.error("[ChecklistGeneratorService] Failed: #{e.message}")
    []
  end

  private

  def post_to_api
    uri  = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"]  = "application/json"
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"

    request.body = {
      model: MODEL,
      max_tokens: 800,
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT
        },
        {
          role: "user",
          content: "Task: \"#{@task_name}\" in #{@city}"
        }
      ]
    }.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

  def parse_items(response)
    text = response.dig("choices", 0, "message", "content") || "[]"
    text = text.gsub(/```json|```/, "").strip
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.error("[ChecklistGeneratorService] JSON parse failed: #{e.message}")
    []
  end
end
