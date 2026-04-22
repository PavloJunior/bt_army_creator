require "test_helper"

class ArmyListItemTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

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

  # Alpha Strike PV Adjustment tests

  test "adjusted_point_value returns base PV at skill 4" do
    @item.skill = 4
    assert_equal 52, @item.adjusted_point_value
  end

  test "adjusted_point_value increases for skill 3 with Atlas (PV 52, bracket +10)" do
    @item.skill = 3
    assert_equal 62, @item.adjusted_point_value
  end

  test "adjusted_point_value increases for skill 0 with Atlas (PV 52, +10 * 4)" do
    @item.skill = 0
    assert_equal 92, @item.adjusted_point_value
  end

  test "adjusted_point_value decreases for skill 5 with Atlas (PV 52, bracket -5)" do
    @item.skill = 5
    assert_equal 47, @item.adjusted_point_value
  end

  test "adjusted_point_value decreases for skill 8 with Atlas (PV 52, -5 * 4)" do
    @item.skill = 8
    assert_equal 32, @item.adjusted_point_value
  end

  test "adjusted_point_value increases for skill 3 with Commando (PV 16, bracket +3)" do
    commando_item = ArmyListItem.new(
      army_list: army_lists(:draft_list),
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 3
    )
    assert_equal 19, commando_item.adjusted_point_value
  end

  test "adjusted_point_value decreases for skill 5 with Commando (PV 16, bracket -2)" do
    commando_item = ArmyListItem.new(
      army_list: army_lists(:draft_list),
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 5
    )
    assert_equal 14, commando_item.adjusted_point_value
  end

  test "adjusted_point_value floors at 1 for low PV high skill" do
    commando_item = ArmyListItem.new(
      army_list: army_lists(:draft_list),
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 8
    )
    assert_equal 8, commando_item.adjusted_point_value
    assert_operator commando_item.adjusted_point_value, :>=, 1
  end

  test "adjusted_point_value returns nil when variant is nil" do
    @item.variant = nil
    assert_nil @item.adjusted_point_value
  end

  # Shared miniatures validation tests

  test "variant_belongs_to_chassis allows cross-chassis variant in same group" do
    list = army_lists(:draft_list)
    item = ArmyListItem.new(
      army_list: list,
      miniature: miniatures(:schrek_mini_1),
      variant: variants(:schrek_ppc_standard)
    )
    assert item.valid?, "Expected item to be valid but got: #{item.errors.full_messages.join(', ')}"
  end

  test "variant_belongs_to_chassis rejects cross-chassis variant outside group" do
    list = army_lists(:draft_list)
    item = ArmyListItem.new(
      army_list: list,
      miniature: miniatures(:atlas_mini),
      variant: variants(:commando_2d)
    )
    assert_not item.valid?
    assert_includes item.errors[:variant].join, "must belong to the same chassis"
  end

  test "variant_belongs_to_chassis still works for ungrouped chassis" do
    assert @item.valid?
  end

  # Tech base validation tests

  test "variant_matches_tech_base allows IS variant on inner_sphere list" do
    list = army_lists(:draft_list)
    list.tech_base = "inner_sphere"
    item = ArmyListItem.new(army_list: list, miniature: miniatures(:atlas_mini), variant: variants(:atlas_d))
    assert item.valid?
  end

  test "variant_matches_tech_base rejects Clan variant on inner_sphere list" do
    list = army_lists(:draft_list)
    list.tech_base = "inner_sphere"
    item = ArmyListItem.new(army_list: list, miniature: miniatures(:timber_wolf_mini), variant: variants(:timber_wolf_prime))
    assert_not item.valid?
    assert_includes item.errors[:variant].join, "Inner Sphere tech base"
  end

  test "variant_matches_tech_base allows Clan variant on clan list" do
    list = army_lists(:draft_list)
    list.tech_base = "clan"
    item = ArmyListItem.new(army_list: list, miniature: miniatures(:timber_wolf_mini), variant: variants(:timber_wolf_prime))
    assert item.valid?
  end

  test "variant_matches_tech_base rejects IS variant on clan list" do
    list = army_lists(:draft_list)
    list.tech_base = "clan"
    item = ArmyListItem.new(army_list: list, miniature: miniatures(:atlas_mini), variant: variants(:atlas_d))
    assert_not item.valid?
    assert_includes item.errors[:variant].join, "Clan tech base"
  end

  test "variant_matches_tech_base allows any variant on mixed list" do
    list = army_lists(:draft_list)
    list.tech_base = "mixed"
    item = ArmyListItem.new(army_list: list, miniature: miniatures(:atlas_mini), variant: variants(:atlas_d))
    assert item.valid?

    item2 = ArmyListItem.new(army_list: list, miniature: miniatures(:timber_wolf_mini), variant: variants(:timber_wolf_prime))
    assert item2.valid?
  end

  test "exceeds_point_cap? uses effective_point_cap with bonus" do
    list = army_lists(:draft_list)
    list.event.update!(point_cap: 50)
    list.bonus_points = 20
    list.save!

    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    # Atlas PV 52 > base cap 50, but effective cap is 70
    assert_not item.exceeds_point_cap?
  end

  # =========================================================================
  # Shared list behaviour
  # =========================================================================

  test "added_by_participant association is optional on non-shared lists" do
    item = army_lists(:draft_list).army_list_items.new(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d)
    )
    assert item.valid?
    assert_nil item.added_by_participant
  end

  test "can associate an ArmyListItem with a SharedArmyListParticipant" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    assert_equal alice, item.reload.added_by_participant
  end

  test "creating an item on a shared list resets active participants' acceptances" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    alice.accept!
    bob.accept!

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )

    assert_nil alice.reload.accepted_at, "Alice's acceptance should be cleared"
    assert_nil bob.reload.accepted_at, "Bob's acceptance should be cleared"
  end

  test "destroying an item on a shared list resets active participants' acceptances" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    alice.accept!
    bob.accept!

    item.destroy!

    assert_nil alice.reload.accepted_at
    assert_nil bob.reload.accepted_at
  end

  test "updating skill on a shared list resets active participants' acceptances" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4,
      added_by_participant: alice
    )
    alice.accept!
    bob.accept!

    item.update!(skill: 3)

    assert_nil alice.reload.accepted_at
    assert_nil bob.reload.accepted_at
  end

  test "items on non-shared lists do not touch participant acceptances" do
    list = army_lists(:draft_list)
    # Should not explode even though there are no shared_participants.
    assert_nothing_raised do
      list.army_list_items.create!(
        miniature: miniatures(:atlas_mini),
        variant: variants(:atlas_d)
      )
    end
  end

  test "creating an item on a shared list broadcasts the full set of DOM updates" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")

    # Expected broadcasts on create:
    # 1. append item → #army_list_items
    # 2. replace #point_total
    # 3. update #army_item_count
    # 4. replace #army_list_actions
    # 5. replace #shared_acceptance_banner
    # 6. replace #shared_participant_roster
    # 7. replace #available_chassis_{chassis.id}
    assert_broadcasts "shared_army_list_#{list.id}", 7 do
      list.army_list_items.create!(
        miniature: miniatures(:atlas_mini),
        variant: variants(:atlas_d),
        added_by_participant: alice
      )
    end
  end

  test "destroying an item on a shared list broadcasts the full set of DOM updates" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )

    # Expected broadcasts on destroy:
    # 1. remove #army_list_item_{id}
    # 2. replace #point_total
    # 3. update #army_item_count
    # 4. replace #army_list_actions
    # 5. replace #shared_acceptance_banner
    # 6. replace #shared_participant_roster
    # 7. replace #available_chassis_{chassis.id}
    assert_broadcasts "shared_army_list_#{list.id}", 7 do
      item.destroy!
    end
  end

  test "items on non-shared lists do not broadcast on the shared stream" do
    list = army_lists(:draft_list)

    assert_no_broadcasts "shared_army_list_#{list.id}" do
      list.army_list_items.create!(
        miniature: miniatures(:atlas_mini),
        variant: variants(:atlas_d)
      )
    end
  end
end
