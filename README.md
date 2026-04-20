Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
**1. Problem Statement**

**Expats arriving in Germany face a dense stack of administrative tasks and receive official letters in formal German they cannot parse. There is no single tool that connects the task list, the documents, and the knowledge needed to act on them. People either pay for help or make costly mistakes.**

**2. Target User**

**Primary: Non-German-speaking expat, aged 25–40, relocating to Berlin, Munich, or Hamburg for work. Has a smartphone and laptop. Is comfortable with digital tools but not with German bureaucracy.**

**3. MVP Scope: Document Scanner**

**The MVP is a single, end-to-end working feature: upload a German bureaucratic PDF, receive an AI-generated plain-English analysis.**

**3.1  What it does**

- User uploads a PDF (German official letter, tax notice, health insurance document, etc.)
- App sends the document to the Anthropic API (Claude)
- Claude returns structured JSON: document type, critical deadline, financial impact, plain-English summary, and 2–3 next steps
- Result is stored in the database and rendered on the analysis view
- User can ask a follow-up question about the document in a simple Q&A interface

**3.2  What the analysis screen shows**

- Document type and category (tax notice, health insurance, housing, etc.)
- Critical deadline, highlighted if it is within 30 days
- Financial impact if there is one (amount owed, potential saving, subsidy deadline)
- Plain-English summary of what the document is actually saying
- 2 to 3 concrete next steps the user should take
- A text field where the user can ask a follow-up question

**3.3  What done looks like**

- User can upload a PDF from the browser
- The analysis result renders correctly with all fields above
- Result is saved so the user can come back to it
- A sensible error message appears if something goes wrong
