# Landed

**Landed** helps non-German-speaking expats navigate German bureaucracy. Upload a German official letter, get a plain-English AI analysis with deadlines, financial impact, and next steps — plus a city-specific admin checklist to track your relocation tasks.

---

## Problem

Expats arriving in Germany face a dense stack of administrative tasks and receive official letters in formal German they cannot parse. There is no single tool that connects the task list, the documents, and the knowledge needed to act on them. People either pay for help or make costly mistakes.

## Target User

Non-German-speaking expat, aged 25–40, relocating to Berlin, Munich, or Hamburg for work. Comfortable with digital tools but not with German bureaucracy.

---

## Features

### Document Scanner (MVP)
- Upload a German bureaucratic PDF (tax notice, health insurance, housing letter, etc.)
- AI analysis via Anthropic Claude returns:
  - Document type and category
  - Critical deadline (highlighted if within 30 days)
  - Financial impact (amounts owed, savings, subsidy deadlines)
  - Plain-English summary
  - 2–3 concrete next steps
- Results saved for later retrieval
- Follow-up Q&A chat interface per document

### City Checklist
- Task checklist tailored to the user's destination city (Berlin, Munich, Hamburg)
- Track completion of each admin task (register address, open bank account, etc.)
- Organized by category with ordered steps

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1.3 |
| Ruby | 3.3.5 |
| Database | PostgreSQL |
| Authentication | Devise |
| Frontend | Hotwire (Turbo + Stimulus), Bootstrap 5.3 |
| Forms | Simple Form |
| File Uploads | Active Storage |
| Background Jobs | Solid Queue (in-process via Puma) |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| AI | Anthropic Claude API |
| Deployment | Kamal + Docker |
| Testing | Minitest, Capybara, Selenium |

---

## Data Model

```
User
 ├── Profile (belongs_to City)
 ├── UserChecklistItems → ChecklistItem → Task → City
 └── Chats → ChecklistItem
       └── Messages
```

- **City** — Berlin, Munich, Hamburg
- **Task** — admin task belonging to a city (e.g. "Register your address")
- **ChecklistItem** — individual step within a task, ordered by position
- **UserChecklistItem** — tracks whether a user has completed a checklist item
- **Chat** — conversation thread linked to a checklist item
- **Message** — individual message in a chat (content + role)

---

## Getting Started

### Prerequisites

- Ruby 3.3.5
- PostgreSQL
- Node.js (for asset compilation)

### Setup

```bash
git clone https://github.com/MartaMajaG/landed.git
cd landed

bundle install
rails db:create db:migrate db:seed

bin/dev
```

App runs at `http://localhost:3000`.

### Environment Variables

Create a `.env` file in the project root (never commit it):

```
ANTHROPIC_API_KEY=your_key_here
```

Sensitive credentials (database passwords, API keys for production) are stored in `config/credentials.yml.enc`. Edit with:

```bash
bin/rails credentials:edit
```

---

## Running Tests

```bash
bin/rails test          # unit + controller tests
bin/rails test:system   # system tests (requires Chrome)
```

---

## Deployment

The app is configured for deployment with [Kamal](https://kamal-deploy.org) using Docker.

```bash
kamal setup    # first deploy
kamal deploy   # subsequent deploys
```

Key Kamal commands:

```bash
kamal console   # Rails console on server
kamal app logs  # tail production logs
kamal shell     # SSH into container
```

Configure `config/deploy.yml` with your server IP and image registry before deploying.

---

## Project Structure

```
app/
  controllers/
    pages_controller.rb       # home page
    tasks_controller.rb       # city task checklist
  models/
    user.rb
    profile.rb
    city.rb
    task.rb
    checklist_item.rb
    user_checklist_item.rb
    chat.rb
    message.rb
  views/
    tasks/                    # checklist views
config/
  routes.rb
db/
  schema.rb
  migrate/
```

---

## Contributing

This project was bootstrapped with the [Le Wagon Rails template](https://github.com/lewagon/rails-templates).
