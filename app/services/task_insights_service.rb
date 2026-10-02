require "net/http"
require "json"

class TaskInsightsService
  API_URL = "https://models.inference.ai.azure.com/chat/completions"
  MODEL   = "gpt-4o-mini"

  # ── Approved resource domains, by category ──
  # LLMs reliably hallucinate plausible-looking URLs/domains from memory —
  # asking the model to "generate a real resource" was producing broken links
  # (deutsche-bank.de, money.de) that don't correspond to real pages. Instead
  # of trusting the model to invent a URL, we give it a closed list of known-
  # real domains to choose from per category, ordered by preference (e.g. N26
  # first for banking, since it's the most foreigner-friendly onboarding).
  # Add new domains here as they're verified — never let the model add its own.
  APPROVED_DOMAINS = {
    "finance_and_banking"      => %w[n26.com deutsche-bank.de commerzbank.de comdirect.de sparkasse.de],
    "housing_and_registration" => %w[muenchen.de service.muenchen.de mvv-muenchen.de],
    "health_and_insurance"     => %w[tk.de aok.de barmer.de bundesgesundheitsministerium.de],
    "legal_and_work"           => %w[arbeitsagentur.de bamf.de make-it-in-germany.com],
  }.freeze

  # NOTE: each tip now carries its own resource link, generated alongside the tip itself
  # instead of being guessed at render time via keyword matching. This replaces the previous
  # separate "quick_links" lookup (a big keyword if/elsif chain in the view) as the source of
  # truth for a tip's linked resource — the two are now one fact, not two independently
  # maintained ones.
  SYSTEM_PROMPT = <<~PROMPT
    You are a German relocation expert advising international expats settling in Munich.
    Generate exactly 3 practical expert tips for the given relocation task.
    Return ONLY a valid JSON array. No markdown fences, no explanation, no preamble.
    Each tip is an object with these keys:
      - "title": a short noun phrase, max 5 words, no trailing punctuation
      - "body": one or two sentences of concrete, factual, Munich-specific advice
      - "resource_domain": OPTIONAL. If the user prompt gives you a list of allowed domains
        for this task's category, and one of them is topically relevant to this specific tip,
        set this to exactly that domain string (nothing else — no path, no https://).
        If none of the allowed domains fit this tip, or no allowed list was given, omit this
        key and "resource_title" entirely rather than inventing a domain or URL.
      - "resource_title": OPTIONAL. Only include if "resource_domain" is included — a short
        name (max 6 words) describing what that domain offers for this tip.
    Never invent a domain, URL, or resource that isn't explicitly in the allowed list you
    were given. A tip with no resource is completely acceptable and expected sometimes.
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
      max_tokens: 700,
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

    allowed = APPROVED_DOMAINS[@task.category.to_s]
    if allowed.present?
      context << "Allowed resource domains for this category (in preference order — " \
                 "prefer earlier ones when more than one fits): #{allowed.join(', ')}"
    else
      context << "No approved resource domains exist for this category — omit " \
                 "resource_domain and resource_title on every tip."
    end

    context.join("\n")
  end

  def parse_tips(response)
    text = response.dig("choices", 0, "message", "content") || "[]"
    text = text.gsub(/```json|```/, "").strip
    parsed = JSON.parse(text)

    parsed
      .select { |tip| tip.is_a?(Hash) && tip["title"].present? && tip["body"].present? }
      .map { |tip| attach_verified_resource(tip) }
  rescue JSON::ParserError => e
    Rails.logger.error("[TaskInsightsService] JSON parse failed for '#{@task.name}': #{e.message}")
    []
  end

  # Even with the whitelist, double-check the model didn't pick a domain outside
  # the approved list for this category, and confirm the domain actually resolves
  # before building a resource_url from it. A tip that fails either check keeps
  # its title/body but drops the resource fields — a tip with no link is far
  # better than a tip with a broken one.
  def attach_verified_resource(tip)
    domain = tip["resource_domain"].to_s.strip.downcase
    allowed = APPROVED_DOMAINS[@task.category.to_s] || []

    if domain.blank? || !allowed.include?(domain) || !domain_reachable?(domain)
      tip.delete("resource_domain")
      tip.delete("resource_title")
      tip.delete("resource_url")
      return tip
    end

    tip["resource_domain"] = domain
    tip["resource_url"]    = "https://#{domain}"
    tip
  end

  def domain_reachable?(domain)
    uri = URI("https://#{domain}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 4
    http.read_timeout = 4
    response = http.request(Net::HTTP::Head.new(uri))
    response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
  rescue StandardError
    false
  end
end
