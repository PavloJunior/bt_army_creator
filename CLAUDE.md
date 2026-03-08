# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BT Army Creator is a Rails 8.1 app for managing BattleTech tournament army lists. Players create army lists for events, selecting miniatures and assigning unit variants. Admins manage chassis, events, and miniatures, and can sync unit data from the Master Unit List (MUL) API (`masterunitlist.info`).

## Tech Stack

Ruby 3.4.8, Rails 8.1, SQLite3, Propshaft, Tailwind CSS v4 (via tailwindcss-rails), importmap-rails (no Node.js), Hotwire (Turbo + Stimulus), Solid Queue/Cache/Cable. Auth is custom cookie-based (`has_secure_password`, no Devise). Deployment via Kamal (Docker).

## Commands

```bash
bin/dev                    # Start dev server (Rails + Tailwind watcher via foreman)
bin/rails test             # Run all tests
bin/rails test test/models/army_list_test.rb           # Run single test file
bin/rails test test/models/army_list_test.rb:42        # Run single test by line
bin/rails test:system      # Run system tests (Capybara + Selenium)
bin/rubocop                # Lint (rubocop-rails-omakase style)
bin/brakeman --no-pager    # Security static analysis
bin/bundler-audit          # Gem vulnerability audit
bin/importmap audit        # JS dependency audit
bin/ci                     # Full local CI: setup, rubocop, security scans, tests, seed test
bin/rails db:prepare       # Create + migrate database
bin/rails db:seed          # Seed eras and factions (idempotent)
```

## Architecture

### Domain Model

The core domain revolves around **Events** that have **ArmyLists** containing **ArmyListItems**. Each item links a **Miniature** (a physical model the player owns) to a **Variant** (a specific unit configuration with stats from MUL).

- **Chassis** → has many **Variants** (synced from MUL API) and **Miniatures**
- **Variant** → has many **VariantFactions** (join to Faction via `mul_id`, not local PK)
- **Event** → has **EventEraRestrictions** and **EventFactionRestrictions** to filter allowed units
- **MiniatureLock** → unique constraint on (miniature_id, event_id) prevents the same mini from being used in multiple lists per event

### Game Systems

Events use either `classic_bt` (points via `battle_value`) or `alpha_strike` (points via `point_value`). `Event#point_value_method` and `Event#point_value_label` abstract this.

### Lifecycles

- **Event**: `upcoming` → `active` → `completed` (admin transitions via dedicated controller actions)
- **ArmyList**: `draft` → `submitted` (player submits; admin can `unlock` back to draft)
- On submit, `MiniatureLock` records are created; race conditions handled by rescuing `ActiveRecord::RecordNotUnique` → `ArmyList::LockConflictError`

### Real-Time Updates

`ArmyList#submit!` broadcasts Turbo Streams to `"event_#{event_id}_miniatures"` to remove locked miniature cards for all connected clients. `unlock` triggers a full page refresh broadcast.

`ArmyListItemsController` responds to `turbo_stream` format for create/destroy (incremental DOM updates).

### Authentication

- **Admin**: Session-based auth via `Authentication` concern. All admin controllers inherit `Admin::BaseController` which enforces `require_authentication`. Admin login at `/admin/session/new`.
- **Public**: No login. Army list ownership tracked via `army_list_ids` signed cookie (set on create, expires day after event). `ArmyListOwnership` concern handles authorization.

### MUL API Integration

`MulClient` (in `app/services/`) wraps Faraday with retries. Background jobs handle syncing:
- `SyncChassisJob` — orchestrator: syncs variants inline, then fans out per-faction and per-card sub-jobs. Creates a `SyncAttempt` record for tracking progress.
- `SyncFactionForChassisJob` — syncs variant-faction associations for one chassis+faction pair. Retries independently.
- `FetchVariantCardJob` — fetches a single unit card image from MUL
- `SyncAttempt` model tracks sync progress (status, counters, errors) with live Turbo Stream updates to the admin dashboard at `/admin/sync_attempts`.

### Routing

Two main namespaces:
- `/admin/*` — authenticated admin panel (chassis CRUD, event management, army list oversight)
- `/` — public event browsing and army list creation/editing/submission

### Testing

Minitest with fixtures. `test/test_helpers/session_test_helper.rb` provides `sign_in_as(user)` and `sign_out` for integration tests. Tests run in parallel by default.
