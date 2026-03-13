require "test_helper"

class ArmyListTest < ActiveSupport::TestCase
  test "total_points for alpha_strike reflects skill adjustments" do
    list = army_lists(:draft_list)
    assert_equal "alpha_strike", list.event.game_system

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    # Atlas PV 52 at skill 3 → 62 (bracket +10 per rating, 1 rating above default)
    assert_equal 62, list.total_points
  end

  test "tech_base defaults to mixed" do
    list = ArmyList.new(event: events(:upcoming_event), player_name: "Player")
    assert_equal "mixed", list.tech_base
  end

  test "tech_base must be valid" do
    list = army_lists(:draft_list)
    list.tech_base = "invalid"
    assert_not list.valid?
    assert list.errors[:tech_base].any?
  end

  test "tech_base_label returns human-readable labels" do
    list = army_lists(:draft_list)
    list.tech_base = "inner_sphere"
    assert_equal "Inner Sphere", list.tech_base_label

    list.tech_base = "clan"
    assert_equal "Clan", list.tech_base_label

    list.tech_base = "mixed"
    assert_equal "Mixed", list.tech_base_label
  end

  test "total_points for classic_bt ignores skill adjustments" do
    list = ArmyList.create!(
      event: events(:active_event),
      player_name: "Classic Player",
      status: "draft"
    )
    assert_equal "classic_bt", list.event.game_system

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    # Classic BT uses battle_value regardless of skill
    assert_equal 1897, list.total_points
  end
end
