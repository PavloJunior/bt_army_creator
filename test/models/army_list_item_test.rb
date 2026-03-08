require "test_helper"

class ArmyListItemTest < ActiveSupport::TestCase
  setup do
    @item = ArmyListItem.new(
      army_list: army_lists(:draft_list),
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d)
    )
  end

  test "skill defaults to 4" do
    assert_equal 4, @item.skill
  end

  test "valid with default skill" do
    assert @item.valid?
  end

  test "skill must be between 0 and 8" do
    @item.skill = -1
    assert_not @item.valid?

    @item.skill = 9
    assert_not @item.valid?

    @item.skill = 0
    assert @item.valid?

    @item.skill = 8
    assert @item.valid?
  end

  test "card_image returns variant card for skill" do
    card = variant_cards(:atlas_d_skill4)
    @item.skill = 4
    @item.save!

    assert_equal card, @item.card_image
  end

  test "card_image returns nil when no card exists for skill" do
    @item.skill = 2
    @item.save!

    assert_nil @item.card_image
  end
end
