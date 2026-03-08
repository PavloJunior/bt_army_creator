# MUL Data Export/Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rake tasks to export all MUL-synced data (chassis, variants, variant_factions) to a JSON file and import it back on another environment.

**Architecture:** Single rake file with two tasks (`mul:export` and `mul:import`). Export builds a nested JSON structure (chassis → variants → variant_factions) and writes to disk. Import reads the JSON and upserts records in a transaction. No new models or migrations needed.

**Tech Stack:** Ruby rake tasks, JSON stdlib, existing ActiveRecord models.

---

### Task 1: Write the export rake task with test

**Files:**
- Create: `lib/tasks/mul.rake`
- Create: `test/tasks/mul_rake_test.rb`

**Step 1: Write the failing test for export**

Create `test/tasks/mul_rake_test.rb`:

```ruby
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
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/tasks/mul_rake_test.rb`
Expected: FAIL — task `mul:export` not defined.

**Step 3: Write the export rake task**

Create `lib/tasks/mul.rake`:

```ruby
namespace :mul do
  desc "Export all MUL-synced data (chassis, variants, variant_factions) to JSON"
  task export: :environment do |_task, args|
    file_path = args.extras.first || ENV.fetch("FILE", Rails.root.join("db", "mul_data_export.json").to_s)

    chassis_data = Chassis.includes(variants: :variant_factions)
                          .where.associated(:variants)
                          .order(:name)
                          .map do |chassis|
      {
        name: chassis.name,
        unit_type: chassis.unit_type,
        tonnage: chassis.tonnage,
        image_url: chassis.image_url,
        variants: chassis.variants.order(:mul_id).map do |variant|
          {
            mul_id: variant.mul_id,
            name: variant.name,
            variant_code: variant.variant_code,
            battle_value: variant.battle_value,
            point_value: variant.point_value,
            tonnage: variant.tonnage,
            unit_type: variant.unit_type,
            technology: variant.technology,
            role: variant.role,
            rules_level: variant.rules_level,
            date_introduced: variant.date_introduced,
            era_id: variant.era_id,
            era_name: variant.era_name,
            image_url: variant.image_url,
            bf_move: variant.bf_move,
            bf_armor: variant.bf_armor,
            bf_structure: variant.bf_structure,
            bf_threshold: variant.bf_threshold,
            bf_damage_short: variant.bf_damage_short,
            bf_damage_medium: variant.bf_damage_medium,
            bf_damage_long: variant.bf_damage_long,
            bf_size: variant.bf_size,
            bf_overheat: variant.bf_overheat,
            bf_abilities: variant.bf_abilities,
            raw_mul_data: variant.raw_mul_data,
            variant_factions: variant.variant_factions.order(:faction_id).map do |vf|
              {
                faction_mul_id: vf.faction_id,
                faction_name: vf.faction_name
              }
            end
          }
        end
      }
    end

    export_data = {
      exported_at: Time.current.iso8601,
      version: 1,
      chassis: chassis_data
    }

    File.write(file_path, JSON.pretty_generate(export_data))

    variant_count = chassis_data.sum { |c| c[:variants].length }
    faction_count = chassis_data.sum { |c| c[:variants].sum { |v| v[:variant_factions].length } }
    puts "Exported #{chassis_data.length} chassis, #{variant_count} variants, #{faction_count} variant_factions to #{file_path}"
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/tasks/mul_rake_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/tasks/mul.rake test/tasks/mul_rake_test.rb
git commit -m "feat: add mul:export rake task for MUL data export"
```

---

### Task 2: Write the import rake task with test

**Files:**
- Modify: `lib/tasks/mul.rake`
- Modify: `test/tasks/mul_rake_test.rb`

**Step 1: Write the failing test for import**

Add to `test/tasks/mul_rake_test.rb`:

```ruby
class MulImportTest < ActiveSupport::TestCase
  setup do
    BtArmyCreator::Application.load_tasks unless Rake::Task.task_defined?("mul:import")
    @import_file = Rails.root.join("tmp", "test_mul_import.json")
  end

  teardown do
    File.delete(@import_file) if File.exist?(@import_file)
  end

  test "imports chassis with variants and variant_factions from JSON" do
    import_data = {
      exported_at: "2026-03-04T12:00:00Z",
      version: 1,
      chassis: [
        {
          name: "Wolverine",
          unit_type: "BattleMech",
          tonnage: 55,
          image_url: "https://example.com/wolverine.png",
          variants: [
            {
              mul_id: 99999,
              name: "Wolverine WVR-6R",
              variant_code: "WVR-6R",
              battle_value: 1101,
              point_value: 30,
              tonnage: 55,
              unit_type: "BattleMech",
              technology: "Inner Sphere",
              role: "Skirmisher",
              rules_level: "Introductory",
              date_introduced: "2575",
              era_id: 10,
              era_name: "Star League",
              image_url: "https://example.com/wolverine_6r.png",
              bf_move: "5/8",
              bf_armor: 5,
              bf_structure: 4,
              bf_threshold: nil,
              bf_damage_short: 2,
              bf_damage_medium: 2,
              bf_damage_long: 1,
              bf_size: 2,
              bf_overheat: nil,
              bf_abilities: nil,
              raw_mul_data: nil,
              variant_factions: [
                { faction_mul_id: 29, faction_name: "Federated Suns" }
              ]
            }
          ]
        }
      ]
    }

    File.write(@import_file, JSON.generate(import_data))

    Rake::Task["mul:import"].reenable
    Rake::Task["mul:import"].invoke(@import_file.to_s)

    chassis = Chassis.find_by(name: "Wolverine")
    assert chassis.present?
    assert_equal "BattleMech", chassis.unit_type
    assert_equal 55, chassis.tonnage
    assert_equal "https://example.com/wolverine.png", chassis.image_url
    assert_equal "2026-03-04T12:00:00Z", chassis.mul_synced_at.iso8601

    variant = Variant.find_by(mul_id: 99999)
    assert variant.present?
    assert_equal chassis.id, variant.chassis_id
    assert_equal "Wolverine WVR-6R", variant.name
    assert_equal 1101, variant.battle_value
    assert_equal 30, variant.point_value

    vf = variant.variant_factions.find_by(faction_id: 29)
    assert vf.present?
    assert_equal "Federated Suns", vf.faction_name
  end

  test "upserts existing records on import" do
    atlas = chassis(:atlas)
    original_id = atlas.id

    import_data = {
      exported_at: "2026-03-04T12:00:00Z",
      version: 1,
      chassis: [
        {
          name: "Atlas",
          unit_type: "BattleMech",
          tonnage: 100,
          image_url: "https://example.com/updated_atlas.png",
          variants: [
            {
              mul_id: 7433,
              name: "Atlas AS7-D",
              variant_code: "AS7-D",
              battle_value: 1900,
              point_value: 53,
              tonnage: 100,
              unit_type: "BattleMech",
              technology: "Inner Sphere",
              role: "Juggernaut",
              rules_level: "Introductory",
              date_introduced: "2755",
              era_id: 10,
              era_name: "Star League",
              image_url: nil,
              bf_move: nil,
              bf_armor: nil,
              bf_structure: nil,
              bf_threshold: nil,
              bf_damage_short: nil,
              bf_damage_medium: nil,
              bf_damage_long: nil,
              bf_size: nil,
              bf_overheat: nil,
              bf_abilities: nil,
              raw_mul_data: nil,
              variant_factions: [
                { faction_mul_id: 29, faction_name: "Federated Suns" }
              ]
            }
          ]
        }
      ]
    }

    File.write(@import_file, JSON.generate(import_data))

    Rake::Task["mul:import"].reenable
    Rake::Task["mul:import"].invoke(@import_file.to_s)

    atlas.reload
    assert_equal original_id, atlas.id
    assert_equal "https://example.com/updated_atlas.png", atlas.image_url

    variant = Variant.find_by(mul_id: 7433)
    assert_equal 1900, variant.battle_value
    assert_equal 53, variant.point_value
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/tasks/mul_rake_test.rb`
Expected: FAIL — task `mul:import` not defined.

**Step 3: Write the import rake task**

Add to `lib/tasks/mul.rake` inside the `namespace :mul` block:

```ruby
  desc "Import MUL-synced data (chassis, variants, variant_factions) from JSON"
  task import: :environment do |_task, args|
    file_path = args.extras.first || ENV.fetch("FILE", Rails.root.join("db", "mul_data_export.json").to_s)

    abort "File not found: #{file_path}" unless File.exist?(file_path)

    data = JSON.parse(File.read(file_path))
    exported_at = Time.zone.parse(data["exported_at"])

    chassis_count = 0
    variant_count = 0
    faction_count = 0

    ActiveRecord::Base.transaction do
      data["chassis"].each do |chassis_data|
        chassis = Chassis.find_or_initialize_by(name: chassis_data["name"])
        chassis.update!(
          unit_type: chassis_data["unit_type"],
          tonnage: chassis_data["tonnage"],
          image_url: chassis_data["image_url"],
          mul_synced_at: exported_at
        )
        chassis_count += 1

        chassis_data["variants"].each do |variant_data|
          variant = Variant.find_or_initialize_by(mul_id: variant_data["mul_id"])
          variant.update!(
            chassis: chassis,
            name: variant_data["name"],
            variant_code: variant_data["variant_code"],
            battle_value: variant_data["battle_value"],
            point_value: variant_data["point_value"],
            tonnage: variant_data["tonnage"],
            unit_type: variant_data["unit_type"],
            technology: variant_data["technology"],
            role: variant_data["role"],
            rules_level: variant_data["rules_level"],
            date_introduced: variant_data["date_introduced"],
            era_id: variant_data["era_id"],
            era_name: variant_data["era_name"],
            image_url: variant_data["image_url"],
            bf_move: variant_data["bf_move"],
            bf_armor: variant_data["bf_armor"],
            bf_structure: variant_data["bf_structure"],
            bf_threshold: variant_data["bf_threshold"],
            bf_damage_short: variant_data["bf_damage_short"],
            bf_damage_medium: variant_data["bf_damage_medium"],
            bf_damage_long: variant_data["bf_damage_long"],
            bf_size: variant_data["bf_size"],
            bf_overheat: variant_data["bf_overheat"],
            bf_abilities: variant_data["bf_abilities"],
            raw_mul_data: variant_data["raw_mul_data"]
          )
          variant_count += 1

          variant_data["variant_factions"].each do |vf_data|
            vf = VariantFaction.find_or_initialize_by(
              variant: variant,
              faction_id: vf_data["faction_mul_id"]
            )
            vf.update!(faction_name: vf_data["faction_name"])
            faction_count += 1
          end
        end
      end
    end

    puts "Imported #{chassis_count} chassis, #{variant_count} variants, #{faction_count} variant_factions from #{file_path}"
  end
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/tasks/mul_rake_test.rb`
Expected: All PASS

**Step 5: Commit**

```bash
git add lib/tasks/mul.rake test/tasks/mul_rake_test.rb
git commit -m "feat: add mul:import rake task for MUL data import"
```

---

### Task 3: Run full test suite and verify no regressions

**Step 1: Run all tests**

Run: `bin/rails test`
Expected: All pass, no regressions.

**Step 2: Run rubocop**

Run: `bin/rubocop`
Expected: No new offenses. Fix any that appear.

**Step 3: Test export/import round-trip manually (if chassis data exists in dev)**

```bash
bin/rails mul:export
cat db/mul_data_export.json | head -50
bin/rails mul:import
```

**Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "chore: fix lint issues in mul rake tasks"
```

---

### Task 4: Add mul_data_export.json to .gitignore

The export file in `db/` is environment-specific data, not source code. But the user may want to check it into git to carry it to production. Ask the user.

**Step 1: Ask user if they want the export file gitignored or checked in**

If gitignored, add to `.gitignore`:
```
/db/mul_data_export.json
```

If checked in, no action needed — it will be committed with the data after export.
