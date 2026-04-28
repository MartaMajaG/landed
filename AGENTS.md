# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev                          # Start development server
bin/setup                        # Initialize or reset dev environment
rails db:migrate                 # Run migrations
rails db:seed                    # Load seed data (cities, tasks, checklist items)
bin/rails test                   # Run Minitest unit/controller tests
bin/rails test:system            # Run system tests (requires Chrome)
bin/rubocop                      # Lint Ruby code
bin/brakeman                     # Static security analysis
bin/bundler-audit                # Audit gems for vulnerabilities
bin/rails credentials:edit       # Edit encrypted credentials
```

## What This App Does

Landed helps expats navigate German bureaucracy. Users upload official German letters (PDFs/images), Codex AI extracts key info (deadline, amount, urgency, advice), and users track relocation tasks via city-specific checklists.

## Data Model

```
User (Devise)
├── Profile (1-1) → belongs_to City
├── UserChecklistItem (many) → belongs_to ChecklistItem, completed: boolean
├── Document (many) → has_one_attached :file, AI-extracted fields
└── Chat (many) → belongs_to ChecklistItem, has_one_attached :document
    └── Message (many) → content, role (user/assistant)

City → has_many Tasks → has_many ChecklistItems → has_many UserChecklistItems
```

The `UserChecklistItem` join table tracks per-user task completion (`find_or_initialize_by` pattern on toggle). Composite unique index on `(user_id, checklist_item_id)`.

## AI Integration

`Document#extract_ai_data` sends the uploaded file to Codex:
- PDFs → `type: "document"` block; images → `type: "image"` block
- Model: `Codex-3-5-sonnet-20240620`, max_tokens: 1000
- Returns JSON with: `title`, `amount`, `deadline`, `urgency`, `document_type`, `advice`
- API key via `ANTHROPIC_API_KEY` env var

`Chat` has an `:ai_ready` Active Storage variant (resize 2048×2048, JPEG q85) for images before sending to AI.

## Key Conventions

- **Image processing:** libvips (not ImageMagick). `auto_orient` is not supported — libvips handles EXIF rotation automatically.
- **File uploads:** `form_with` requires explicit `multipart: true`. Two separate hidden file inputs: one standard upload (`accept: "image/*,application/pdf"`) and one camera-only (`capture="environment"`, images only).
- **Camera button visibility:** Controlled by `.camera-only` CSS class in `_document_scanner.scss` — hidden on desktop via `display: none !important`, shown on touch devices via `(hover: none) and (pointer: coarse)` media query. The `!important` is required to override Bootstrap's `.btn`.
- **Stimulus:** One custom controller — `uploadpreview_controller.js` — shows instant image preview via `URL.createObjectURL` before upload.
- **Forms:** Simple Form with Bootstrap integration. `collection_select` used for `checklist_item_id` association on Chat.

## Routes Overview

```ruby
root "pages#home"
devise_for :users
resources :documents, only: [:create, :show, :index]
resources :chats, only: [:index, :show, :new, :create] do
  resources :messages, only: [:create]
end
resource :profile, only: [:edit, :update, :show]
resources :tasks, only: [:index, :show]
resources :user_checklist_items, only: [:update]
```

## Deployment

Kamal + Docker. `config/deploy.yml` orchestrates. Health check: `GET /up`. Production secrets in `.kamal/secrets`; use `bin/rails credentials:edit` for app secrets.
