module SpecialsHelper
  def specials_data_tag
    specials = Special.all.index_by(&:abbreviation).transform_values do |s|
      { name: s.full_name, desc: s.description }
    end
    tag.div(id: "specials-data", data: { specials: specials.to_json }, class: "hidden")
  end

  def render_ability_buttons(bf_abilities_string)
    return "".html_safe if bf_abilities_string.blank?

    abbreviations = Special.abbreviations_longest_first
    tokens = bf_abilities_string.split(/,\s*/)

    safe_join(tokens.map { |token| ability_tag(token, abbreviations) }, " ")
  end

  private

  def ability_tag(token, abbreviations)
    base = abbreviations.find do |abbr|
      next unless token.start_with?(abbr)
      remainder = token[abbr.length..]
      remainder.empty? || remainder.match?(/\A[^a-zA-Z]/)
    end

    if base
      tag.button(token,
        type: "button",
        class: "inline-block px-1.5 py-0.5 text-xs rounded border border-hud-border " \
               "text-hud-green-dim hover:text-hud-green hover:border-hud-green-dim " \
               "cursor-pointer bg-transparent transition-colors",
        data: {
          action: "special-ability-modal#show",
          special_abbreviation: base,
          special_token: token
        })
    else
      tag.span(token, class: "inline-block px-1.5 py-0.5 text-xs text-hud-text-dim")
    end
  end
end
