require "test_helper"

class FactionTest < ActiveSupport::TestCase
  test "for_tech_base inner_sphere includes Inner Sphere category factions" do
    result = Faction.for_tech_base("inner_sphere")
    assert_includes result, factions(:federated_suns)
  end

  test "for_tech_base inner_sphere excludes Clan category factions" do
    result = Faction.for_tech_base("inner_sphere")
    assert_not_includes result, factions(:clan_wolf)
  end

  test "for_tech_base clan includes Clan category factions" do
    result = Faction.for_tech_base("clan")
    assert_includes result, factions(:clan_wolf)
  end

  test "for_tech_base clan excludes Inner Sphere category factions" do
    result = Faction.for_tech_base("clan")
    assert_not_includes result, factions(:federated_suns)
  end

  test "for_tech_base with unknown tech base returns empty" do
    assert_empty Faction.for_tech_base("unknown")
  end
end
