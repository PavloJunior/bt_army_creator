require "test_helper"

class EventTest < ActiveSupport::TestCase
  # --- themed validation ---

  test "themed event with two sides is valid" do
    event = events(:themed_event)
    assert event.valid?
    assert_equal 2, event.event_sides.count
  end

  test "themed event with fewer than two sides is invalid" do
    event = events(:themed_event)
    # Remove one side to leave only 1
    event.event_sides.last.destroy
    assert_equal 1, event.event_sides.reload.count

    assert_not event.valid?
    assert event.errors[:base].any? { |msg| msg.include?("between 2 and 4 sides") }
  end

  test "themed event with more than four sides is invalid" do
    event = events(:themed_event)
    # Add 3 more sides to reach 5 total
    3.times do |i|
      event.event_sides.create!(name: "Extra #{i}", point_cap: 100, position: i + 3)
    end
    assert_equal 5, event.event_sides.reload.count

    assert_not event.valid?
    assert event.errors[:base].any? { |msg| msg.include?("between 2 and 4 sides") }
  end

  test "themed event with four sides is valid" do
    event = Event.new(
      name: "Four Sides",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 800,
      status: "upcoming",
      themed: true
    )
    4.times do |i|
      event.event_sides.build(name: "Side #{i}", point_cap: 200, position: i + 1)
    end

    assert event.valid?
  end

  test "non-themed event does not require sides" do
    event = events(:upcoming_event)
    assert_not event.themed?
    assert_equal 0, event.event_sides.count
    assert event.valid?
  end

  test "non-themed event without sides is valid" do
    event = Event.new(
      name: "Standard Event",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 200,
      status: "upcoming",
      themed: false
    )
    assert event.valid?
  end

  # =========================================================================
  # available_variants_for_chassis — Standard Events
  # =========================================================================

  test "standard event: no restrictions returns all usable variants for chassis" do
    event = events(:upcoming_event)
    result = event.available_variants_for_chassis(chassis(:hunchback))
    assert_includes result, variants(:hunchback_4g)
    assert_includes result, variants(:hunchback_4p)
    assert_not_includes result, variants(:hunchback_zero), "zero-PV variant must never appear"
  end

  test "standard event: tech_base inner_sphere excludes Clan technology variants" do
    event = events(:upcoming_event)
    result = event.available_variants_for_chassis(chassis(:timber_wolf), tech_base: "inner_sphere")
    assert_not_includes result, variants(:timber_wolf_prime), "Clan tech variant excluded from IS tech base"
  end

  test "standard event: tech_base clan excludes Inner Sphere technology variants" do
    event = events(:upcoming_event)
    result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "clan")
    assert_not_includes result, variants(:atlas_d), "IS tech variant excluded from Clan tech base"
  end

  test "standard event: tech_base mixed returns both IS and Clan variants" do
    event = events(:upcoming_event)
    is_result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "mixed")
    assert_includes is_result, variants(:atlas_d)

    clan_result = event.available_variants_for_chassis(chassis(:timber_wolf), tech_base: "mixed")
    assert_includes clan_result, variants(:timber_wolf_prime)
  end

  test "standard event: Mixed technology variant visible under inner_sphere tech base if faction matches" do
    event = events(:upcoming_event)
    # Bushwacker BSW-X1 has technology: "Mixed" and faction: FedSuns (IS faction)
    # IS tech base excludes "Clan" technology, but "Mixed" is NOT "Clan"
    result = event.available_variants_for_chassis(chassis(:bushwacker), tech_base: "inner_sphere")
    assert_includes result, variants(:bushwacker_x1),
      "Mixed-tech variant should be visible under IS tech base since it's not excluded and faction matches"
  end

  test "standard event: Mixed technology variant visible under clan tech base only if faction matches clan" do
    event = events(:upcoming_event)
    # Bushwacker BSW-X1 has technology: "Mixed" and factions: FedSuns + Mercenary
    # Clan tech base excludes "Inner Sphere" technology. "Mixed" != "Inner Sphere" so not excluded.
    # BUT faction filter: Faction.for_tech_base("clan") doesn't include FedSuns(29) or Mercenary(34) unless they're in TECH_BASE_EXTRA_MUL_IDS
    # Mercenary(34) IS in inner_sphere extra IDs, NOT in clan extra IDs
    result = event.available_variants_for_chassis(chassis(:bushwacker), tech_base: "clan")
    assert_not_includes result, variants(:bushwacker_x1),
      "Mixed-tech variant not visible under Clan tech base because its factions don't map to Clan"
  end

  test "standard event: faction_mul_ids further filters within tech base" do
    event = events(:upcoming_event)
    # Hunchback 4G has factions: FedSuns(29), ComStar(18), Mercenary(34), Draconis(25)
    # Filter to just Draconis Combine
    result = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "inner_sphere", faction_mul_ids: [ 25 ])
    assert_includes result, variants(:hunchback_4g), "4G has Draconis faction"
    assert_includes result, variants(:hunchback_4p), "4P has Draconis faction"
  end

  test "standard event: faction_mul_ids filtering excludes variants without that faction" do
    event = events(:upcoming_event)
    # Filter to ComStar(18) — Hunchback 4G has ComStar, 4P does not
    result = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "inner_sphere", faction_mul_ids: [ 18 ])
    assert_includes result, variants(:hunchback_4g), "4G has ComStar"
    assert_not_includes result, variants(:hunchback_4p), "4P does NOT have ComStar"
  end

  test "standard event: event faction restrictions whitelist factions" do
    event = events(:upcoming_event)
    # Add restriction: only Clan Wolf allowed
    event.event_faction_restrictions.create!(faction_mul_id: 24, faction_name: "Clan Wolf")

    result = event.available_variants_for_chassis(chassis(:timber_wolf))
    assert_includes result, variants(:timber_wolf_prime), "Clan Wolf variant passes restriction"

    atlas_result = event.available_variants_for_chassis(chassis(:atlas))
    assert_not_includes atlas_result, variants(:atlas_d), "FedSuns variant blocked by restriction"
  end

  test "standard event: event faction restrictions intersect with tech base factions" do
    event = events(:upcoming_event)
    # Restrict to FedSuns only
    event.event_faction_restrictions.create!(faction_mul_id: 29, faction_name: "Federated Suns")

    # Clan tech base: FedSuns(29) is NOT in Faction.for_tech_base("clan")
    # Intersection of [29] & clan_faction_ids = empty
    result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "clan")
    assert_empty result, "IS faction restricted + clan tech base = no results"
  end

  test "standard event: era restrictions filter by era_id" do
    event = events(:upcoming_event)
    # Restrict to Clan Invasion era only (era_id 13)
    event.event_era_restrictions.create!(era_mul_id: 13, era_name: "Clan Invasion")

    # Atlas is Star League era (era_id 10) — excluded
    result = event.available_variants_for_chassis(chassis(:atlas))
    assert_not_includes result, variants(:atlas_d), "Star League era variant excluded by Clan Invasion restriction"

    # Hunchback 4P is Clan Invasion era (era_id 13) — included
    result = event.available_variants_for_chassis(chassis(:hunchback))
    assert_includes result, variants(:hunchback_4p), "Clan Invasion era variant passes"
    assert_not_includes result, variants(:hunchback_4g), "Star League era variant excluded"
  end

  test "standard event: unusable variants never returned regardless of filters" do
    event = events(:upcoming_event)
    result = event.available_variants_for_chassis(chassis(:hunchback))
    assert_not_includes result, variants(:hunchback_zero)

    result_mixed = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "mixed")
    assert_not_includes result_mixed, variants(:hunchback_zero)

    result_is = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "inner_sphere")
    assert_not_includes result_is, variants(:hunchback_zero)
  end

  test "standard event: no duplicate variants when variant has multiple matching factions" do
    event = events(:upcoming_event)
    # Hunchback 4G has 4 factions (FedSuns, ComStar, Mercenary, Draconis) — should appear once
    result = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "inner_sphere")
    assert_equal 1, result.select { |v| v.id == variants(:hunchback_4g).id }.count
  end

  # =========================================================================
  # available_variants_for_chassis — Themed Events
  # =========================================================================

  test "themed event: side factions filter variants" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # ComStar side has FedSuns(29) — Atlas has FedSuns faction
    result = event.available_variants_for_chassis(chassis(:atlas), event_side: comstar_side)
    assert_includes result, variants(:atlas_d)
  end

  test "themed event: side factions exclude variants from other factions" do
    event = events(:themed_event)
    clan_side = event_sides(:clan_side)

    # Clan side has Clan Wolf(24) — Atlas only has FedSuns(29) and ComStar(18), no Clan Wolf
    result = event.available_variants_for_chassis(chassis(:atlas), event_side: clan_side)
    assert_not_includes result, variants(:atlas_d)
  end

  test "themed event: clan side returns clan variants" do
    event = events(:themed_event)
    clan_side = event_sides(:clan_side)

    result = event.available_variants_for_chassis(chassis(:timber_wolf), event_side: clan_side)
    assert_includes result, variants(:timber_wolf_prime)
    assert_includes result, variants(:timber_wolf_a)
  end

  test "themed event: side with multiple clan factions returns variants from any of them" do
    event = events(:themed_event)
    clan_side = event_sides(:clan_side)
    # Add Jade Falcon to clan side
    clan_side.event_side_factions.create!(faction_mul_id: 17, faction_name: "Clan Jade Falcon")

    # Dire Wolf Prime only has Jade Falcon faction
    result = event.available_variants_for_chassis(chassis(:dire_wolf), event_side: clan_side)
    assert_includes result, variants(:dire_wolf_prime)

    # Timber Wolf has both Wolf and Jade Falcon — still returned once
    tw_result = event.available_variants_for_chassis(chassis(:timber_wolf), event_side: clan_side)
    assert_includes tw_result, variants(:timber_wolf_prime)
    assert_equal 1, tw_result.select { |v| v.id == variants(:timber_wolf_prime).id }.count
  end

  test "themed event: tech_base inner_sphere + side factions intersection" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Side has FedSuns(29). IS tech base faction IDs include FedSuns. Intersection: [29]
    result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "inner_sphere", event_side: comstar_side)
    assert_includes result, variants(:atlas_d)
  end

  test "themed event: tech_base clan excludes IS-tech variants even from IS factions on the side" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Atlas has technology "Inner Sphere" → excluded by clan tech base technology filter
    result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "clan", event_side: comstar_side)
    assert_empty result
  end

  test "themed event: tech_base clan + clan side returns clan variants" do
    event = events(:themed_event)
    clan_side = event_sides(:clan_side)

    result = event.available_variants_for_chassis(chassis(:timber_wolf), tech_base: "clan", event_side: clan_side)
    assert_includes result, variants(:timber_wolf_prime)
  end

  test "themed event: tech_base inner_sphere excludes Clan-tech variants even from Clan factions" do
    event = events(:themed_event)
    clan_side = event_sides(:clan_side)

    # Timber Wolf has technology "Clan" → excluded by IS tech base technology filter
    result = event.available_variants_for_chassis(chassis(:timber_wolf), tech_base: "inner_sphere", event_side: clan_side)
    assert_empty result
  end

  test "themed event: Mixed technology variant with IS faction visible under IS tech base" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Bushwacker X1: technology "Mixed", faction FedSuns(29)
    # IS tech base excludes "Clan" tech. "Mixed" != "Clan" so not excluded.
    # FedSuns(29) is in IS tech base. Intersection: [29]. Variant has faction 29.
    result = event.available_variants_for_chassis(chassis(:bushwacker), tech_base: "inner_sphere", event_side: comstar_side)
    assert_includes result, variants(:bushwacker_x1),
      "Mixed-tech variant visible under IS tech base because faction matches and technology isn't excluded"
  end

  test "themed event: Mixed technology variant IS visible under clan tech base — side factions are the scope" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Bushwacker X1: technology "Mixed", faction FedSuns(29)
    # Clan tech base excludes "Inner Sphere". "Mixed" != "Inner Sphere" so not excluded.
    # For themed events, no faction-tech-base intersection — side factions define the scope.
    # FedSuns(29) is a side faction, variant has that faction → visible.
    result = event.available_variants_for_chassis(chassis(:bushwacker), tech_base: "clan", event_side: comstar_side)
    assert_includes result, variants(:bushwacker_x1),
      "Mixed-tech variant visible under Clan tech base in themed events — side factions are the scope"
  end

  test "themed event: Mixed tech base shows all variants from side factions without technology exclusion" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Mixed tech base: no technology exclusion, faction_filter_ids stays as side factions [29]
    atlas_result = event.available_variants_for_chassis(chassis(:atlas), tech_base: "mixed", event_side: comstar_side)
    assert_includes atlas_result, variants(:atlas_d)

    bush_result = event.available_variants_for_chassis(chassis(:bushwacker), tech_base: "mixed", event_side: comstar_side)
    assert_includes bush_result, variants(:bushwacker_x1)
  end

  test "themed event: player faction_mul_ids further narrows within side factions" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)
    # Add ComStar(18) to the side too
    comstar_side.event_side_factions.create!(faction_mul_id: 18, faction_name: "ComStar")

    # Side now has FedSuns(29) + ComStar(18)
    # Player selects only ComStar(18)
    result = event.available_variants_for_chassis(
      chassis(:hunchback), tech_base: "inner_sphere",
      event_side: comstar_side, faction_mul_ids: [ 18 ]
    )
    # Hunchback 4G has ComStar faction → included
    assert_includes result, variants(:hunchback_4g)
    # Hunchback 4P does NOT have ComStar → excluded
    assert_not_includes result, variants(:hunchback_4p)
  end

  test "themed event: era restrictions combine with side faction filtering" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Restrict to Clan Invasion era only
    event.event_era_restrictions.create!(era_mul_id: 13, era_name: "Clan Invasion")

    # Atlas is Star League era → excluded
    result = event.available_variants_for_chassis(chassis(:atlas), event_side: comstar_side)
    assert_not_includes result, variants(:atlas_d)

    # Hunchback 4P is Clan Invasion era + has FedSuns faction → included
    hb_result = event.available_variants_for_chassis(chassis(:hunchback), event_side: comstar_side)
    assert_includes hb_result, variants(:hunchback_4p)
    assert_not_includes hb_result, variants(:hunchback_4g), "Star League era excluded"
  end

  test "themed event: unusable variants never returned" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    result = event.available_variants_for_chassis(chassis(:hunchback), event_side: comstar_side)
    assert_not_includes result, variants(:hunchback_zero)
  end

  test "themed event: variant shared between both sides appears on each side independently" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)
    clan_side = event_sides(:clan_side)

    # Add a faction to both sides that shares a variant
    # Give Mercenary(34) to both sides, Commando 2D has Mercenary faction
    comstar_side.event_side_factions.create!(faction_mul_id: 34, faction_name: "Mercenary")
    clan_side.event_side_factions.create!(faction_mul_id: 34, faction_name: "Mercenary")

    cs_result = event.available_variants_for_chassis(chassis(:commando), tech_base: "inner_sphere", event_side: comstar_side)
    cl_result = event.available_variants_for_chassis(chassis(:commando), tech_base: "inner_sphere", event_side: clan_side)

    # Mercenary(34) is in IS tech base extra IDs → intersection works for both sides
    assert_includes cs_result, variants(:commando_2d)
    assert_includes cl_result, variants(:commando_2d)
  end

  test "themed event: event_side takes precedence over event_faction_restrictions" do
    event = events(:themed_event)
    comstar_side = event_sides(:comstar_side)

    # Add event-level faction restriction (should be ignored for themed events)
    event.event_faction_restrictions.create!(faction_mul_id: 24, faction_name: "Clan Wolf")

    # Side has FedSuns(29). Event restriction says Clan Wolf(24).
    # Side should take precedence.
    result = event.available_variants_for_chassis(chassis(:atlas), event_side: comstar_side)
    assert_includes result, variants(:atlas_d), "Side factions override event-level faction restrictions"
  end

  # =========================================================================
  # available_variants_for_chassis — Classic BT game system
  # =========================================================================

  test "classic BT event: filters by battle_value > 0 instead of point_value" do
    event = events(:active_event) # classic_bt game system
    # All test variants have both BV and PV > 0, so they should appear
    result = event.available_variants_for_chassis(chassis(:atlas))
    assert_includes result, variants(:atlas_d)
  end

  # =========================================================================
  # available_variants_for_chassis — Edge cases
  # =========================================================================

  test "edge case: variant with no variant_factions is excluded when any faction filter is active" do
    event = events(:upcoming_event)
    # Create a variant with no faction associations
    orphan = Variant.create!(
      chassis: chassis(:hunchback), mul_id: 77777, name: "Orphan HBK",
      technology: "Inner Sphere", battle_value: 100, point_value: 10, era_id: 10
    )

    # With tech base filter (which activates faction filtering)
    result = event.available_variants_for_chassis(chassis(:hunchback), tech_base: "inner_sphere")
    assert_not_includes result, orphan, "Variant with no factions excluded by tech base faction filter"

    # Without any filter — no faction_filter_ids, so no faction join
    result_no_filter = event.available_variants_for_chassis(chassis(:hunchback))
    assert_includes result_no_filter, orphan, "Variant with no factions included when no faction filtering"
  end

  test "edge case: empty side factions returns nothing" do
    event = events(:themed_event)
    empty_side = event.event_sides.create!(name: "Empty Side", point_cap: 100, position: 3)
    # No event_side_factions added

    result = event.available_variants_for_chassis(chassis(:atlas), event_side: empty_side)
    assert_empty result
  end

  test "edge case: all era restrictions exclude everything" do
    event = events(:upcoming_event)
    # Restrict to era 999 which no variant belongs to
    event.event_era_restrictions.create!(era_mul_id: 999, era_name: "Future Era")

    result = event.available_variants_for_chassis(chassis(:atlas))
    assert_empty result
  end

  test "edge case: faction_mul_ids with no matching variants returns empty" do
    event = events(:upcoming_event)
    result = event.available_variants_for_chassis(chassis(:atlas), faction_mul_ids: [ 99999 ])
    assert_empty result
  end

  # =========================================================================
  # shared_army_list flag
  # =========================================================================

  test "shared_army_list and themed are mutually exclusive" do
    event = Event.new(
      name: "Bad Shared Themed",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 400,
      status: "upcoming",
      themed: true,
      shared_army_list: true,
      shared_tech_base: "inner_sphere"
    )
    assert_not event.valid?
    assert event.errors[:base].any? { |msg| msg.include?("shared") && msg.include?("themed") }
  end

  test "shared_army_list event without themed is valid" do
    event = Event.new(
      name: "Scouring Sands",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 400,
      status: "upcoming",
      themed: false,
      shared_army_list: true,
      shared_tech_base: "inner_sphere"
    )
    assert event.valid?
  end

  test "non-shared, non-themed event is valid" do
    event = Event.new(
      name: "Plain Event",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 200,
      status: "upcoming"
    )
    assert event.valid?
  end

  test "creating a shared event auto-creates a draft army list with supplied tech_base" do
    event = Event.create!(
      name: "Scouring Sands Auto",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 400,
      status: "upcoming",
      shared_army_list: true,
      shared_tech_base: "inner_sphere"
    )

    list = event.shared_army_list_record
    assert list.present?, "shared event must auto-create an army list"
    assert_equal "draft", list.status
    assert_equal "inner_sphere", list.tech_base
    assert_includes list.player_name, "Scouring Sands Auto"
  end

  test "creating a non-shared event does not auto-create any army list" do
    event = Event.create!(
      name: "No Auto List",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 200,
      status: "upcoming"
    )
    assert_equal 0, event.army_lists.count
  end

  test "shared_army_list_record returns nil for non-shared events" do
    event = events(:upcoming_event)
    assert_nil event.shared_army_list_record
  end

  test "updating a shared event tech_base on a draft empty list flows through" do
    event = Event.create!(
      name: "Tech Sync Draft",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 400,
      status: "upcoming",
      shared_army_list: true,
      shared_tech_base: "inner_sphere"
    )

    event.update!(shared_tech_base: "clan")
    assert_equal "clan", event.shared_army_list_record.reload.tech_base
  end

  test "updating a shared event tech_base is blocked when the list has items" do
    event = Event.create!(
      name: "Tech Sync Blocked",
      date: "2026-06-01",
      game_system: "alpha_strike",
      point_cap: 400,
      status: "upcoming",
      shared_army_list: true,
      shared_tech_base: "inner_sphere"
    )
    list = event.shared_army_list_record
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    assert_not event.update(shared_tech_base: "clan"),
      "update should be rejected by validation"
    assert_includes event.errors[:shared_tech_base].join,
      "contains units"
    assert_equal "inner_sphere", list.reload.tech_base,
      "tech_base must not change once items exist"
  end
end
