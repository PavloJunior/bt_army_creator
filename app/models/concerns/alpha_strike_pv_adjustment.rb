module AlphaStrikePvAdjustment
  extend ActiveSupport::Concern

  # Lookup tables mapping base PV ranges to per-skill-rating adjustments.
  # Source: Alpha Strike Commander's Edition, PV Skill Adjustment Table.

  PV_INCREASE_BRACKETS = [
    (0..7), (8..12), (13..17), (18..22), (23..27),
    (28..32), (33..37), (38..42), (43..47), (48..52)
  ].freeze

  PV_DECREASE_BRACKETS = [
    (0..14), (15..24), (25..34), (35..44), (45..54),
    (55..64), (65..74), (75..84), (85..94), (95..104)
  ].freeze

  def adjusted_point_value
    return nil unless variant&.point_value

    base_pv = variant.point_value
    return base_pv if skill == 4

    if skill < 4
      base_pv + (4 - skill) * increase_per_rating(base_pv)
    else
      [base_pv - (skill - 4) * decrease_per_rating(base_pv), 1].max
    end
  end

  private

  def increase_per_rating(base_pv)
    PV_INCREASE_BRACKETS.each_with_index do |range, index|
      return index + 1 if range.cover?(base_pv)
    end
    (base_pv + 2) / 5
  end

  def decrease_per_rating(base_pv)
    PV_DECREASE_BRACKETS.each_with_index do |range, index|
      return index + 1 if range.cover?(base_pv)
    end
    (base_pv - 5) / 10 + 1
  end
end
