# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start development server
bin/dev                        # runs rails server (no separate JS build needed — importmap)

# Database
bin/rails db:migrate
bin/rails db:seed

# Tests
bin/rails test                              # all unit + controller tests
bin/rails test test/models/user_test.rb     # single test file
bin/rails test:system                       # system tests (requires Chrome)

# Code quality
bin/rubocop                    # lint
bin/brakeman                   # security scan
bundle exec bundler-audit check --update   # dependency vulnerability scan

# Credentials
bin/rails credentials:edit     # edit encrypted credentials (requires RAILS_MASTER_KEY)
```

## Architecture

### Request Flow

All routes require authentication (`before_action :authenticate_user!` in `ApplicationController`) except `PagesController#home`. Devise handles auth.

On signup, `User` automatically creates a `Profile` via an `after_create` callback — the profile is expected to always exist for a logged-in user.

### City-Scoped Data

Everything is scoped to `current_user.profile.city`. Tasks and checklist items belong to a `City`, and `TasksController#index` filters by `current_user.profile.city_id`. If a user has no city set, this will raise a nil error — city selection happens on profile edit.

### Checklist Progress

`UserChecklistItem` is a join model between `User` and `ChecklistItem` with a `completed` boolean. Toggling is done via `button_to` PATCH to `UserChecklistItemsController#update`, which uses `find_or_initialize_by` so the record is created on first toggle.

### Chats & Messages

`Chat` belongs to both a `User` and a `ChecklistItem`, and has an Active Storage PDF attachment (`:pdf`). `Message` belongs to `Chat` and stores `content` + `role` (intended values: `"user"` / `"assistant"`). The AI analysis pipeline (sending PDFs to Anthropic Claude, parsing the response) is not yet implemented — `chats/show` currently shows a "Processing…" placeholder.

### Frontend

No Node.js/npm — assets are managed via Rails importmap (`config/importmap.rb`). Bootstrap 5.3 and Stimulus are pinned there. To add a new Stimulus controller, create `app/javascript/controllers/my_controller.js` — it is eager-loaded automatically via `index.js`.

### Multiple Databases (Production)

`config/database.yml` defines four separate databases for production: `primary`, `cache`, `queue`, and `cable`, each sourced from a distinct env var (`DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL`). Solid Queue runs inside the Puma process (`SOLID_QUEUE_IN_PUMA=true`).

### Generator Config

Generators are configured in `config/application.rb` to skip assets, helpers, and fixtures. Don't expect those to be generated automatically.
