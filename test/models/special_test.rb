require "test_helper"

class SpecialTest < ActiveSupport::TestCase
  setup do
    Special.reset_abbreviations_cache
  end

  test "validates abbreviation presence" do
    special = Special.new(full_name: "Test")
    assert_not special.valid?
    assert special.errors[:abbreviation].any?
  end

  test "validates full_name presence" do
    special = Special.new(abbreviation: "TST")
    assert_not special.valid?
    assert special.errors[:full_name].any?
  end

  test "validates abbreviation uniqueness" do
    special = Special.new(abbreviation: "ENE", full_name: "Duplicate")
    assert_not special.valid?
    assert special.errors[:abbreviation].any?
  end

  test "parse_base returns exact match for simple abbreviation" do
    assert_equal "ENE", Special.parse_base("ENE")
  end

  test "parse_base strips numeric suffix" do
    assert_equal "IF", Special.parse_base("IF2")
  end

  test "parse_base strips slash-separated parameters" do
    assert_equal "AC", Special.parse_base("AC2/2/0")
  end

  test "parse_base matches CASEII before CASE" do
    assert_equal "CASEII", Special.parse_base("CASEII")
  end

  test "parse_base matches LMAS before MAS" do
    assert_equal "LMAS", Special.parse_base("LMAS")
  end

  test "parse_base matches C3BSM before C3M" do
    assert_equal "C3BSM", Special.parse_base("C3BSM3")
  end

  test "parse_base handles REAR with slashes" do
    assert_equal "REAR", Special.parse_base("REAR1/1/1/0")
  end

  test "parse_base handles SRM with slashes" do
    assert_equal "SRM", Special.parse_base("SRM2/2")
  end

  test "parse_base returns nil for unknown abbreviation" do
    assert_nil Special.parse_base("ZZZZZ")
  end

  test "abbreviations_longest_first returns sorted list" do
    abbrs = Special.abbreviations_longest_first
    assert abbrs.length > 0
    # Check sorted by length descending
    abbrs.each_cons(2) do |a, b|
      assert a.length >= b.length, "Expected #{a} (#{a.length}) >= #{b} (#{b.length})"
    end
  end
end
