class Special < ApplicationRecord
  validates :abbreviation, presence: true, uniqueness: true
  validates :full_name, presence: true

  def self.abbreviations_longest_first
    @abbreviations_longest_first ||= order(Arel.sql("LENGTH(abbreviation) DESC")).pluck(:abbreviation)
  end

  def self.reset_abbreviations_cache
    @abbreviations_longest_first = nil
  end

  def self.parse_base(token)
    abbreviations_longest_first.find do |abbr|
      next unless token.start_with?(abbr)
      remainder = token[abbr.length..]
      remainder.empty? || remainder.match?(/\A[^a-zA-Z]/)
    end
  end
end
