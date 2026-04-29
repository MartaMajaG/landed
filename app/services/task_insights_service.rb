require "net/http"
require "json"

class TaskInsightsService
  API_URL = "https://models.inference.ai.azure.com/chat/completions"
  MODEL   = "gpt-4o-mini"

  SYSTEM_PROMPT = <<~PROMPT
    You are a German relocation expert advising international expats settling in Munich.
    Generate exactly 3 practical expert tips for the given relocation task.
    Return ONLY a valid JSON array. No markdown fences, no explanation, no preamble.
    Each tip is an object with exactly two keys:
      - "title": a short noun phrase, max 5 words, no trailing punctuation
      - "body": one or two sentences of concrete, factual, Munich-specific advice
    The tips must be genuinely useful and specific — avoid generic statements.
  PROMPT

  def initialize(task)
    @task = task
  end

  def call
    response = post_to_api
    parse_tips(response)
  rescue StandardError => e
    Rails.logger.error("[TaskInsightsService] Failed for '#{@task.name}': #{e.message}")
    []
  end

  private

  def post_to_api
    uri  = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl    = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"]  = "application/json"
    request["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"

    request.body = {
      model:      MODEL,
      max_tokens: 500,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user",   content: user_prompt }
      ]
    }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end

  def user_prompt
    context = []
    context << "Task: \"#{@task.name}\""
    context << "Description: #{@task.description}" if @task.description.present?
    context << "Category: #{@task.category}"       if @task.category.present?
    context.join("\n")
  end

  def parse_tips(response)
    text = response.dig("choices", 0, "message", "content") || "[]"
    text = text.gsub(/```json|```/, "").strip
    parsed = JSON.parse(text)
    # Validate structure — each item must have title and body
    parsed.select { |tip| tip.is_a?(Hash) && tip["title"].present? && tip["body"].present? }
  rescue JSON::ParserError => e
    Rails.logger.error("[TaskInsightsService] JSON parse failed for '#{@task.name}': #{e.message}")
    []
  end
end
