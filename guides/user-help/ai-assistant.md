# Portfolio AI Assistant

The Portfolio AI Assistant is a conversational interface that lets you ask questions about your application portfolio using natural language. Instead of navigating dashboards and running reports, you can simply ask questions and get instant answers drawn from your live portfolio data.

---

## Getting Started

Navigate to the **Chat** tab in the top navigation bar to open the AI Assistant. You'll see a text input at the bottom of the screen where you can type your question.

### What You Can Ask

The assistant has access to six types of portfolio data:

- **Portfolio summary** — application counts, TIME/PAID distribution, assessment completion, crown jewels, tech debt totals
- **Application listing** — find applications matching filters (workspace, criticality, tech health, TIME quadrant, PAID action) and get a structured list back
- **Cost analysis** — run rates, vendor spend, budget status, cost gaps
- **Technology risk** — rank applications by combined criticality and tech health, surface the highest-risk apps in any workspace
- **Application detail** — deep dive on any specific application by name (scores, costs, integrations, ownership, lifecycle)
- **Workspace listing** — see which departments/workspaces exist and their application counts

### Example Questions

**Simple lookups:**
- "How many applications do we have?"
- "Who are our top 5 vendors by spend?"
- "Tell me about SAP ERP"
- "What's our total annual run rate?"

**Listing and ranking:**
- "Show me applications in the Finance department"
- "Which workspaces have the most applications?"
- "List my crown jewel applications"
- "Which applications have the worst tech health?"

**Risk and priority questions:**
- "Which of my crown jewel applications are at highest risk? Rank them."
- "What's the top risk in the Police Department workspace right now?"
- "Which apps need urgent attention?"

**Multi-dimensional analysis:**
- "Give me a SWOT analysis of my Finance portfolio from a CIO's perspective"
- "If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"
- "If we retired our CAD system tomorrow, what integrations break and what other systems are affected?"

**Rationalization and consolidation:**
- "We have two overlapping CRM systems. Which one should we rationalize to?"
- "Which of my finance applications could be consolidated?"

---

## Conversations

Each chat session is saved as a conversation. You can:

- **Start a new conversation** using the "New Chat" button in the header
- **View previous conversations** in the sidebar (click the menu icon to toggle)
- **Switch between conversations** by clicking on them in the sidebar
- **Delete a conversation** using the trash icon next to it

Conversations are automatically titled based on your first message.

---

## Data Scope

The assistant only shows data you have permission to see, based on your role:

- **Namespace administrators** see data across all workspaces
- **Workspace-scoped users** see data for their assigned workspaces only

A badge in the chat header shows your current data scope (e.g., "All Workspaces" or your workspace name).

If you notice results seem limited, it's because the assistant respects the same access controls as the rest of the application. Contact your administrator if you need broader access.

---

## Department and Workspace Filtering

You can ask questions about specific departments or workspaces by name:

- "What's the cost breakdown for the Police department?"
- "How many apps does Finance have?"
- "Show me the IT Services workspace"

The assistant will automatically match department names to workspaces and scope the results accordingly.

---

## Copying Responses

Hover over any assistant response to reveal a copy button. Click it to copy the full response text to your clipboard.

---

## Tips

- **Be specific** — "What's our total annual run rate?" works better than "Tell me about costs"
- **Ask follow-up questions** — the assistant remembers your conversation context
- **Name applications exactly** — when asking about a specific app, use its full name for best results
- **Try different angles** — if one question doesn't give you what you need, rephrase it

---

## When the Assistant Can't Answer

The assistant is designed to fail gracefully when you ask about something it doesn't have access to. Instead of guessing or fabricating an answer, it will say so clearly and suggest what it CAN tell you instead. Examples of questions that produce a graceful refusal:

- **Trends over time** — "How has our tech debt changed over the last 6 months?" The portfolio model captures the current state only; there are no historical snapshots. The assistant will offer a current-state baseline as an alternative.
- **Data classification (PII, PHI, GDPR, HIPAA)** — "Which applications handle PII?" Data sensitivity categories are not currently tracked in the portfolio. The assistant will not infer classification from application names; it will pivot to assessment status, ownership, and criticality instead.

If a graceful refusal isn't what you wanted, rephrase your question around the data the assistant DOES have (assessment scores, costs, lifecycle status, ownership, integrations).

---

## Error Messages

If you see one of these messages, here's what they mean:

- **"Claude is rate-limited right now. Please wait about N minutes and try again."** — The portfolio AI hit its per-minute or per-day usage limit on the underlying language model. Wait the suggested time and retry. If this happens repeatedly, contact your administrator — your namespace may need a higher tier on the AI provider.
- **"Claude is temporarily unavailable. Please try again in a minute."** — A transient server issue. Just retry.
- **"Your session has expired. Please refresh the page and sign in again."** — Your login token timed out. Refresh the page.
- **"Couldn't reach the server. Please check your connection and try again."** — A network or connectivity issue between your browser and the GetInSync servers.

When the underlying AI provider returns extra detail about why it failed (e.g. "exceeded daily input token limit"), that detail is included after the main message so you can see exactly what happened.

---

## Current Limitations

- The assistant cannot modify any data — it is read-only
- Roadmap status and data quality analysis are coming soon
- The assistant does not store historical snapshots, so it cannot answer "trend" questions about your portfolio
- The assistant does not currently track data classification labels (PII, PHI, GDPR scope, etc.)
