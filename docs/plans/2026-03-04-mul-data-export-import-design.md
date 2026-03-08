# MUL Data Export/Import

## Purpose

Rake tasks to export MUL-synced data from dev and import it on production, avoiding the need to re-sync from the MUL API on deploy.

## Decisions

- **Format**: Single nested JSON file (chassis → variants → variant_factions)
- **Interface**: Rake tasks (`mul:export`, `mul:import`)
- **Import mode**: Upsert (find-or-create by unique key, update attributes)
- **Scope**: chassis, variants, variant_factions only. No images, eras, factions, or user data.
- **Default path**: `db/mul_data_export.json`, overridable via `FILE` env var

## File Structure

```json
{
  "exported_at": "2026-03-04T12:00:00Z",
  "version": 1,
  "chassis": [
    {
      "name": "Atlas",
      "unit_type": "BattleMech",
      "tonnage": 100,
      "image_url": "https://...",
      "variants": [
        {
          "mul_id": 7433,
          "name": "Atlas AS7-D",
          "variant_code": "AS7-D",
          "battle_value": 1897,
          "point_value": 52,
          "tonnage": 100,
          "unit_type": "BattleMech",
          "technology": "Inner Sphere",
          "role": "Juggernaut",
          "rules_level": "Standard",
          "date_introduced": 2755,
          "era_id": 10,
          "era_name": "Star League",
          "image_url": "...",
          "bf_move": "3",
          "bf_armor": 8,
          "bf_structure": 8,
          "bf_threshold": 4,
          "bf_damage_short": 5,
          "bf_damage_medium": 5,
          "bf_damage_long": 3,
          "bf_size": 4,
          "bf_overheat": 1,
          "bf_abilities": "...",
          "raw_mul_data": { ... },
          "variant_factions": [
            { "faction_mul_id": 14, "faction_name": "Federated Suns" }
          ]
        }
      ]
    }
  ]
}
```

## Export Task (`mul:export`)

- Default output: `db/mul_data_export.json`
- Optional `FILE=path/to/file.json` env var
- `Chassis.includes(variants: :variant_factions).find_each`
- Skip chassis with no variants
- Print count summary to stdout

## Import Task (`mul:import`)

- Default input: `db/mul_data_export.json`
- Optional `FILE=path/to/file.json` env var
- Wrap in transaction
- Upsert chassis by `name`, variants by `mul_id`, variant_factions by `(variant_id, faction_id)`
- Set `chassis.mul_synced_at` to exported_at timestamp
- Print count summary to stdout

## Implementation

- Single file: `lib/tasks/mul.rake`
- Test: `test/tasks/mul_rake_test.rb`

## Testing

- Create chassis/variant/variant_faction records
- Export to temp file
- Clear the tables
- Import from temp file
- Assert records match originals
