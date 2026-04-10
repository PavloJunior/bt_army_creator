require "test_helper"

class EventSideTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid with all required attributes" do
    side = event_sides(:comstar_side)
    assert side.valid?
  end

  test "invalid without name" do
    side = event_sides(:comstar_side)
    side.name = nil
    assert_not side.valid?
    assert side.errors[:name].any?
  end

  test "invalid without point_cap" do
    side = event_sides(:comstar_side)
    side.point_cap = nil
    assert_not side.valid?
    assert side.errors[:point_cap].any?
  end

  test "invalid with point_cap of zero" do
    side = event_sides(:comstar_side)
    side.point_cap = 0
    assert_not side.valid?
    assert side.errors[:point_cap].any?
  end

  test "invalid with negative point_cap" do
    side = event_sides(:comstar_side)
    side.point_cap = -10
    assert_not side.valid?
    assert side.errors[:point_cap].any?
  end

  test "invalid without position" do
    side = event_sides(:comstar_side)
    side.position = nil
    assert_not side.valid?
    assert side.errors[:position].any?
  end

  test "max_players allows nil" do
    side = event_sides(:clan_side)
    assert_nil side.max_players
    assert side.valid?
  end

  test "invalid with max_players of zero" do
    side = event_sides(:comstar_side)
    side.max_players = 0
    assert_not side.valid?
    assert side.errors[:max_players].any?
  end

  test "invalid with negative max_players" do
    side = event_sides(:comstar_side)
    side.max_players = -1
    assert_not side.valid?
    assert side.errors[:max_players].any?
  end

  # --- per_player_point_cap ---

  test "per_player_point_cap returns point_cap when no players" do
    side = event_sides(:comstar_side)
    assert_equal 0, side.player_count
    assert_equal 300, side.per_player_point_cap
  end

  test "per_player_point_cap returns point_cap when one player" do
    side = event_sides(:comstar_side)
    ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")

    assert_equal 1, side.player_count
    assert_equal 300, side.per_player_point_cap
  end

  test "per_player_point_cap returns point_cap divided by player count when two players" do
    side = event_sides(:comstar_side)
    ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")
    ArmyList.create!(event: side.event, event_side: side, player_name: "Player 2", status: "draft", tech_base: "mixed")

    assert_equal 2, side.player_count
    assert_equal 150, side.per_player_point_cap
  end

  test "per_player_point_cap returns point_cap divided by player count when three players" do
    side = event_sides(:comstar_side)
    3.times do |i|
      ArmyList.create!(event: side.event, event_side: side, player_name: "Player #{i}", status: "draft", tech_base: "mixed")
    end

    assert_equal 3, side.player_count
    assert_equal 100, side.per_player_point_cap
  end

  test "per_player_point_cap uses integer division that floors" do
    side = event_sides(:comstar_side)
    # 300 / 7 = 42.857... -> floors to 42
    7.times do |i|
      ArmyList.create!(event: side.event, event_side: side, player_name: "Player #{i}", status: "draft", tech_base: "mixed")
    end

    assert_equal 7, side.player_count
    assert_equal 42, side.per_player_point_cap
  end

  # --- projected_per_player_point_cap ---

  test "projected_per_player_point_cap returns point_cap when no players" do
    side = event_sides(:comstar_side)
    assert_equal 0, side.player_count
    # 300 / (0 + 1) = 300
    assert_equal 300, side.projected_per_player_point_cap
  end

  test "projected_per_player_point_cap returns point_cap / 2 when one player" do
    side = event_sides(:comstar_side)
    ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")

    assert_equal 1, side.player_count
    # 300 / (1 + 1) = 150
    assert_equal 150, side.projected_per_player_point_cap
  end

  # --- full? ---

  test "full? returns false when no max_players set" do
    side = event_sides(:clan_side)
    assert_nil side.max_players
    assert_not side.full?
  end

  test "full? returns false when under max_players" do
    side = event_sides(:comstar_side)
    assert_equal 3, side.max_players
    ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")

    assert_equal 1, side.player_count
    assert_not side.full?
  end

  test "full? returns true when at max_players" do
    side = event_sides(:comstar_side)
    assert_equal 3, side.max_players
    3.times do |i|
      ArmyList.create!(event: side.event, event_side: side, player_name: "Player #{i}", status: "draft", tech_base: "mixed")
    end

    assert_equal 3, side.player_count
    assert side.full?
  end

  # --- player_count ---

  test "player_count counts only non-inactive lists" do
    side = event_sides(:comstar_side)
    ArmyList.create!(event: side.event, event_side: side, player_name: "Active Player", status: "draft", tech_base: "mixed")
    ArmyList.create!(event: side.event, event_side: side, player_name: "Submitted Player", status: "submitted", submitted_at: Time.current, tech_base: "mixed")
    ArmyList.create!(event: side.event, event_side: side, player_name: "Inactive Player", status: "inactive", tech_base: "mixed")

    assert_equal 2, side.player_count
  end

  # --- available_tech_bases ---

  test "available_tech_bases includes inner_sphere when side has IS-tech variants" do
    side = event_sides(:comstar_side)
    # comstar_side has Federated Suns → Atlas (IS tech) is available
    bases = side.available_tech_bases
    assert_includes bases, "inner_sphere"
  end

  test "available_tech_bases includes clan when side has Clan-tech variants" do
    side = event_sides(:clan_side)
    # clan_side has Clan Wolf → Timber Wolf (Clan tech) is available
    bases = side.available_tech_bases
    assert_includes bases, "clan"
  end

  test "available_tech_bases returns only inner_sphere when all variants are IS-tech" do
    event = events(:themed_event)
    # Create a side with only Draconis Combine — only has IS-tech variants (hunchback_4g, 4p)
    side = event.event_sides.create!(name: "DC Only", point_cap: 100, position: 3)
    side.event_side_factions.create!(faction_mul_id: 25, faction_name: "Draconis Combine")

    bases = side.available_tech_bases
    assert_equal [ "inner_sphere" ], bases
  end

  test "available_tech_bases returns only clan when all variants are Clan-tech" do
    event = events(:themed_event)
    # Create a side with only Jade Falcon — only has Clan-tech variants (dire_wolf, timber_wolf)
    side = event.event_sides.create!(name: "JF Only", point_cap: 100, position: 3)
    side.event_side_factions.create!(faction_mul_id: 17, faction_name: "Clan Jade Falcon")

    bases = side.available_tech_bases
    assert_equal [ "clan" ], bases
  end

  test "available_tech_bases includes mixed when both IS and Clan tech exist" do
    side = event_sides(:comstar_side)
    # Add Clan Wolf faction so side has both IS-tech (Atlas) and Clan-tech (Timber Wolf) variants
    EventSideFaction.create!(event_side: side, faction_mul_id: 24, faction_name: "Clan Wolf")

    bases = side.available_tech_bases
    assert_includes bases, "inner_sphere"
    assert_includes bases, "clan"
    assert_includes bases, "mixed"
  end

  test "available_tech_bases: Mixed-tech variant makes both IS and Clan bases available" do
    side = event_sides(:comstar_side)
    # comstar_side has FedSuns → Bushwacker X1 is Mixed-tech, which passes both
    # IS exclusion (Mixed ≠ Clan) and Clan exclusion (Mixed ≠ Inner Sphere)
    bases = side.available_tech_bases
    assert_includes bases, "inner_sphere"
    assert_includes bases, "clan", "Mixed-tech variant is not excluded by Clan tech base filter"
    assert_includes bases, "mixed"
  end

  test "available_tech_bases returns empty for side with no factions" do
    event = events(:themed_event)
    empty_side = event.event_sides.create!(name: "Empty", point_cap: 100, position: 3)

    assert_equal [], empty_side.available_tech_bases
  end

  # --- allowed_tech_bases override ---

  test "available_tech_bases uses allowed_tech_bases when set" do
    side = event_sides(:comstar_side)
    # Auto-detect would return all three, but admin restricts to IS only
    side.update!(allowed_tech_bases: [ "inner_sphere" ])

    assert_equal [ "inner_sphere" ], side.available_tech_bases
  end

  test "available_tech_bases override can restrict to clan only" do
    side = event_sides(:clan_side)
    side.update!(allowed_tech_bases: [ "clan" ])

    assert_equal [ "clan" ], side.available_tech_bases
  end

  test "available_tech_bases override allows multiple bases" do
    side = event_sides(:comstar_side)
    side.update!(allowed_tech_bases: [ "inner_sphere", "mixed" ])

    assert_equal [ "inner_sphere", "mixed" ], side.available_tech_bases
  end

  test "available_tech_bases falls back to auto-detect when allowed_tech_bases is empty" do
    side = event_sides(:comstar_side)
    side.update!(allowed_tech_bases: [])

    # Should auto-detect (comstar_side has FedSuns → IS + Mixed-tech variants)
    bases = side.available_tech_bases
    assert_includes bases, "inner_sphere"
  end

  test "available_tech_bases falls back to auto-detect when allowed_tech_bases is nil" do
    side = event_sides(:comstar_side)
    side.update!(allowed_tech_bases: nil)

    bases = side.available_tech_bases
    assert_includes bases, "inner_sphere"
  end

  test "available_tech_bases override filters out invalid values" do
    side = event_sides(:comstar_side)
    side.update!(allowed_tech_bases: [ "inner_sphere", "bogus", "clan" ])

    bases = side.available_tech_bases
    assert_equal [ "inner_sphere", "clan" ], bases
    assert_not_includes bases, "bogus"
  end

  # --- recalculate_caps! ---

  test "recalculate_caps! unlocks all submitted lists on the side" do
    side = event_sides(:comstar_side)
    side.event.update!(status: "active")

    list1 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")
    list1.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    list1.submit!

    list2 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 2", status: "draft", tech_base: "mixed")
    list2.army_list_items.create!(miniature: miniatures(:commando_mini), variant: variants(:commando_2d), skill: 4)
    list2.submit!

    # Both should be submitted
    assert list1.reload.submitted?
    assert list2.reload.submitted?

    side.recalculate_caps!

    # Both should be back to draft
    assert list1.reload.draft?
    assert list2.reload.draft?
  end

  test "recalculate_caps! does not affect draft lists" do
    side = event_sides(:comstar_side)
    draft_list = ArmyList.create!(event: side.event, event_side: side, player_name: "Drafter", status: "draft", tech_base: "mixed")

    side.recalculate_caps!

    assert draft_list.reload.draft?
  end

  # --- Draft-reset on player count change ---

  test "deactivating a list on a side recalculates and unlocks submitted lists" do
    side = event_sides(:comstar_side)
    side.event.update!(status: "active")

    # Create two lists and submit them
    list1 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")
    list1.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    list1.submit!

    list2 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 2", status: "draft", tech_base: "mixed")
    list2.army_list_items.create!(miniature: miniatures(:commando_mini), variant: variants(:commando_2d), skill: 4)
    list2.submit!

    assert list1.reload.submitted?
    assert list2.reload.submitted?

    # Deactivate list2 — should trigger recalculate_caps! which unlocks list1
    list2.deactivate!

    assert list1.reload.draft?
    assert list2.reload.inactive?
  end

  test "destroying a list on a side recalculates and unlocks submitted lists" do
    side = event_sides(:comstar_side)
    side.event.update!(status: "active")

    list1 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "mixed")
    list1.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    list1.submit!

    list2 = ArmyList.create!(event: side.event, event_side: side, player_name: "Player 2", status: "draft", tech_base: "mixed")

    assert list1.reload.submitted?

    # Destroy list2 — should trigger after_destroy callback → recalculate_caps!
    list2.destroy!

    assert list1.reload.draft?
  end

  test "deactivating a list on a standard event does not trigger recalculate" do
    event = events(:active_event)
    list1 = ArmyList.create!(event: event, player_name: "Player 1", status: "draft", tech_base: "mixed")
    list1.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    list1.submit!

    list2 = ArmyList.create!(event: event, player_name: "Player 2", status: "draft", tech_base: "mixed")
    list2.army_list_items.create!(miniature: miniatures(:commando_mini), variant: variants(:commando_2d), skill: 4)
    list2.submit!

    assert list1.reload.submitted?
    assert list2.reload.submitted?

    # Deactivate list2 — no event_side, so no recalculate should happen
    list2.deactivate!

    # list1 should remain submitted (not reset to draft)
    assert list1.reload.submitted?
    assert list2.reload.inactive?
  end
end
