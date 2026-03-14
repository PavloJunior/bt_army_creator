class Faction < ApplicationRecord
  has_many :variant_factions, primary_key: :mul_id, foreign_key: :faction_id

  validates :mul_id, presence: true, uniqueness: true
  validates :name, presence: true

  # Category-based mapping
  TECH_BASE_CATEGORIES = {
    "inner_sphere" => [ "Inner Sphere", "Periphery", "Star League" ],
    "clan" => [ "Clan" ]
  }.freeze

  # Explicit mul_id overrides for "Other" and "General" factions
  TECH_BASE_EXTRA_MUL_IDS = {
    "inner_sphere" => [ 18, 34, 38, 44, 48, 49, 55, 56, 57, 90, 102 ],
    "clan" => [ 56, 85 ]
  }.freeze

  SIDEBAR_CATEGORY_ORDER = [ "Inner Sphere", "Clan", "Periphery", "Star League", "Other", "General" ].freeze

  scope :for_tech_base, ->(tech_base) {
    categories = TECH_BASE_CATEGORIES[tech_base] || []
    extra_ids = TECH_BASE_EXTRA_MUL_IDS[tech_base] || []
    where(category: categories).or(where(mul_id: extra_ids))
  }

  def self.for_sidebar(tech_base)
    scope = tech_base == "mixed" ? order(:name) : for_tech_base(tech_base).order(:name)
    scope.group_by(&:category).sort_by { |cat, _| SIDEBAR_CATEGORY_ORDER.index(cat) || 99 }.to_h
  end
end
