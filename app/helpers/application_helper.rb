module ApplicationHelper

  PILLAR_ICONS = {
    "legal_and_work"           => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/></svg>',
    "housing_and_registration" => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>',
    "finance_and_banking"      => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>',
    "health_and_insurance"     => '<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
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
    slug     = task.pillar.slug
    icon_svg = PILLAR_ICONS.fetch(slug, "").html_safe
    content_tag(:span, class: "tag tag-pillar--#{slug}") do
      concat content_tag(:span, icon_svg, class: "lucide-icon", style: "color:inherit;")
      concat task.pillar.name
    end
  end

  # ... other helper methods ...
end
