require "test_helper"

class EventSideFactionTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    faction = event_side_factions(:comstar_side_fedsuns)
    assert faction.valid?
  end

  test "invalid without faction_name" do
    faction = EventSideFaction.new(
      event_side: event_sides(:comstar_side),
      faction_mul_id: 99
    )
    faction.faction_name = nil
    assert_not faction.valid?
    assert faction.errors[:faction_name].any?
  end

  test "faction_mul_id must be unique within an event_side" do
    existing = event_side_factions(:comstar_side_fedsuns)
    duplicate = EventSideFaction.new(
      event_side: existing.event_side,
      faction_mul_id: existing.faction_mul_id,
      faction_name: "Duplicate"
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:faction_mul_id].any?
  end

  test "same faction_mul_id allowed on different event_sides" do
    faction = EventSideFaction.new(
      event_side: event_sides(:clan_side),
      faction_mul_id: 29,
      faction_name: "Federated Suns"
    )
    assert faction.valid?
  end
end
