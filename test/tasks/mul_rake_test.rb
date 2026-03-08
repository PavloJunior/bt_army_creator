require "test_helper"
require "rake"

class MulExportTest < ActiveSupport::TestCase
  setup do
    BtArmyCreator::Application.load_tasks unless Rake::Task.task_defined?("mul:export")
    @export_file = Rails.root.join("tmp", "test_mul_export.json")
  end

  teardown do
    File.delete(@export_file) if File.exist?(@export_file)
  end

  test "exports chassis with variants and variant_factions to JSON" do
    Rake::Task["mul:export"].reenable
    Rake::Task["mul:export"].invoke(@export_file.to_s)

    assert File.exist?(@export_file)

    data = JSON.parse(File.read(@export_file))

    assert_equal 1, data["version"]
    assert data["exported_at"].present?

    exported_chassis = data["chassis"]
    assert exported_chassis.length >= 2

    atlas = exported_chassis.find { |c| c["name"] == "Atlas" }
    assert atlas.present?
    assert_equal "BattleMech", atlas["unit_type"]
    assert_equal 100, atlas["tonnage"]

    atlas_variants = atlas["variants"]
    assert atlas_variants.length >= 1

    atlas_d = atlas_variants.find { |v| v["mul_id"] == 7433 }
    assert atlas_d.present?
    assert_equal "Atlas AS7-D", atlas_d["name"]
    assert_equal 1897, atlas_d["battle_value"]
    assert_equal 52, atlas_d["point_value"]

    factions = atlas_d["variant_factions"]
    assert factions.length >= 1
    assert factions.any? { |f| f["faction_mul_id"] == 29 && f["faction_name"] == "Federated Suns" }
  end
end
