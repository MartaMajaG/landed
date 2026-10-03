module ApplicationHelper

  # Turns an AI chat reply into safe HTML: keeps line breaks and lists,
  # and renders **bold** as real bold instead of showing the asterisks.
  def format_ai_reply(text)
    escaped = ERB::Util.html_escape(text.to_s).to_str
    escaped = escaped.gsub(/\*\*(.+?)\*\*/m, '<strong>\\1</strong>').gsub("**", "")
    simple_format(escaped)
  end

  PILLAR_ICONS = {
    "legal_and_work"           => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/></svg>',
    "housing_and_registration" => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>',
    "finance_and_banking"      => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>',
    "health_and_insurance"     => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
  }.freeze

  # Pillar accent colors — single source of truth for the hex values used as
  # inline backgrounds wherever CSS classes alone can't reach (e.g. the
  # pillar-filter dropdown dots). Matches the --accent custom properties set
  # on .task-card--pillar-* in dashboard.scss — keep these in sync if a
  # pillar's color ever changes.
  PILLAR_ACCENT_COLORS = {
    "legal_and_work"           => "#5B21B6",
    "housing_and_registration" => "#f97316",
    "finance_and_banking"      => "#059669",
    "health_and_insurance"     => "#ec4899",
  }.freeze

  # NOTE: PILLAR_COLORS was removed. It hardcoded a second, independent color per pillar
  # (finance_and_banking => #246DD5, a blue) that was applied via inline style="color: ..."
  # on the icon span — this silently overrode currentColor and caused the icon to render
  # blue even after .tag-pillar--finance_and_banking's CSS text color was fixed to green.
  # This was the same root-cause pattern as the earlier calendar/pillar mismatch: a third
  # place defining pillar color independently of the single source of truth in the SCSS.
  # Now the icon span carries no inline color at all, so it inherits currentColor from the
  # parent .tag-pillar--{slug} class — icon and text can never drift out of sync again.

  def pillar_chip(task)
    return unless task.pillar
    pillar_chip_for(task.pillar.slug, task.pillar.name)
  end

  # Same chip without a Task record (used by the landing page's product preview)
  def pillar_chip_for(slug, name)
    icon_svg = PILLAR_ICONS.fetch(slug, "").html_safe
    content_tag(:span, class: "pillar-chip tag-pillar--#{slug}") do
      concat content_tag(:span, icon_svg, class: "pillar-chip__icon")
      concat content_tag(:span, name, class: "pillar-chip__label")
    end
  end

  def pillar_accent_color(slug)
    PILLAR_ACCENT_COLORS.fetch(slug, "#9ca3af")
  end

  # Returns the first sentence of `text`, truncated to `max_length` characters
  # on a word boundary if that sentence itself runs long. Used for task card
  # descriptions so every card gets a similarly-sized snippet instead of a
  # CSS line-clamp that can cut off mid-word or mid-sentence.
  def first_sentence(text, max_length: 90)
    return "" if text.blank?
    match = text.to_s.match(/[^.!?]+[.!?]+/)
    sentence = match ? match[0].strip : text.strip
    truncate(sentence, length: max_length, separator: " ")
  end

  # Suggested chat questions for a scanned document, based on what kind of
  # document it is. Overdue documents lead with what to do now.
  # skip: questions already covered by a button on the page.
  DOCUMENT_QUESTIONS = [
    [/fine|bu(ss|ß)geld|penalty|mahnung|reminder/, ["How do I pay this?", "Can I contest this?", "What happens if I don't pay?"]],
    [/tax|finanzamt|steuer/, ["How do I pay this?", "What if I can't pay in full?", "Can I object to this?"]],
    [/residence|visa|aufenthalt|ausl(ä|ae)nder|permit/, ["Do I need an appointment?", "What do I need to bring?", "What happens if I miss it?"]],
    [/registration|anmeldung|b(ü|ue)rgeramt|meld/, ["Do I need an appointment?", "What do I need to bring?", "Is there anything else I need to do after?"]],
    [/insurance|krankenkasse|versicherung/, ["What does this cover?", "Do I need to send anything back?", "How do I change or cancel it?"]],
    [/rent|lease|miet|contract|vertrag/, ["What's my notice period?", "What am I committing to?", "Are there any extra costs?"]],
    [/bill|utility|rundfunk|broadcast|strom|gas|water|wasser|fee|geb(ü|ue)hr/, ["How do I pay this?", "Can I set up a direct debit?", "What if I think it's wrong?"]]
  ].freeze

  def document_questions(chat, skip: [])
    text = "#{chat.document_type} #{chat.title}".downcase
    questions = DOCUMENT_QUESTIONS.find { |pattern, _| text.match?(pattern) }&.last
    questions ||= [
      "What do I need to do next?",
      "Is there a deadline?",
      chat.amount.to_f > 0 ? "How do I pay this?" : "Who can I contact about this?"
    ]
    questions -= skip

    if chat.deadline.present? && chat.deadline < Date.today
      (["What happens now that it's overdue?"] + questions).first(3)
    else
      questions.first(3)
    end
  end
end
