require "test_helper"

class SpecialsHelperTest < ActionView::TestCase
  include SpecialsHelper

  setup do
    Special.reset_abbreviations_cache
  end

  test "render_ability_buttons returns empty for blank string" do
    assert_equal "", render_ability_buttons(nil)
    assert_equal "", render_ability_buttons("")
  end

  test "render_ability_buttons renders button for known ability" do
    result = render_ability_buttons("ENE")
    assert_includes result, "<button"
    assert_includes result, "ENE"
    assert_includes result, 'data-special-abbreviation="ENE"'
    assert_includes result, 'data-action="special-ability-modal#show"'
  end

  test "render_ability_buttons renders span for unknown ability" do
    result = render_ability_buttons("ZZZZZ")
    assert_includes result, "<span"
    assert_includes result, "ZZZZZ"
    assert_not_includes result, "<button"
  end

  test "render_ability_buttons handles parameterized abilities" do
    result = render_ability_buttons("IF2")
    assert_includes result, "<button"
    assert_includes result, "IF2"
    assert_includes result, 'data-special-abbreviation="IF"'
    assert_includes result, 'data-special-token="IF2"'
  end

  test "render_ability_buttons handles multiple abilities" do
    result = render_ability_buttons("ENE, IF2, AC2/2/0")
    assert_includes result, 'data-special-abbreviation="ENE"'
    assert_includes result, 'data-special-abbreviation="IF"'
    assert_includes result, 'data-special-abbreviation="AC"'
  end

  test "render_ability_buttons handles mix of known and unknown" do
    result = render_ability_buttons("ENE, UNKNOWN123")
    # ENE should be a button
    assert_match(/<button[^>]*>ENE<\/button>/, result)
    # UNKNOWN123 should be a span
    assert_match(/<span[^>]*>UNKNOWN123<\/span>/, result)
  end
end
