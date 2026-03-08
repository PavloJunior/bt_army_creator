# Admin Chassis Show Page

## Context

The admin panel shows zero variant detail — just a count on the chassis index page. All variant data (stats, roles, card images) synced from MUL is invisible to admins. We need a chassis show page as the primary management hub.

## Design

### Chassis Show Page (`/admin/chassis/:id`)

**Header section:**
- Chassis name, unit type, tonnage, sync status (time ago or "Never")
- Sync button (re-trigger MUL sync)
- Back link to chassis index

**Miniatures section:**
- List of miniatures with label, notes
- Edit/delete actions per miniature
- Add miniature button

**Variants table (compact):**

| Name | Variant Code | PV | BV | Tonnage | Role | Technology | Era | Rules |

Each row is expandable (click to toggle). Expanded content shows:
- Left: Alpha Strike card image (from VariantCard skill 4, if available)
- Right: Full BF stats — Move, Damage S/M/L, OV, Armor, Structure, Size, Abilities

Expand/collapse via Stimulus controller (no server round-trip).

### Simplified Chassis Index

Remove inline miniature management from index. Show:
- Chassis name (linked to show page)
- Unit type, tonnage, variant count, miniature count, last sync
- Actions: Sync, Edit, Delete

### Technical Approach

- Add `:show` to admin chassis routes (change `except: [:show]` to full CRUD)
- Add `show` action to `Admin::ChassisController` with eager loading
- Create `app/views/admin/chassis/show.html.erb`
- Create `app/views/admin/chassis/_variant_row.html.erb` partial
- Create `variant-expand` Stimulus controller
- Simplify `app/views/admin/chassis/index.html.erb`
