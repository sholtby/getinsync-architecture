# Portfolio AI Assistant

The Portfolio AI Assistant is a conversational interface that lets you ask questions about your application portfolio using natural language. Instead of navigating dashboards and running reports, you can simply ask questions and get instant answers drawn from your live portfolio data.

---

## Getting Started

Navigate to the **Chat** tab in the top navigation bar to open the AI Assistant. You'll see a text input at the bottom of the screen where you can type your question.

### What You Can Ask

The assistant has access to four types of portfolio data:

- **Portfolio summary** — application counts, TIME/PAID distribution, assessment completion, crown jewels
- **Cost analysis** — run rates, vendor spend, budget status, cost gaps
- **Application detail** — deep dive on any specific application by name
- **Workspace listing** — see which departments/workspaces exist and their application counts

### Example Questions

- "How many applications do we have?"
- "Who are our top 5 vendors by spend?"
- "Tell me about SAP ERP"
- "What's our total annual run rate?"
- "Show me applications in the Finance department"
- "Which workspaces have the most applications?"

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

## Current Limitations

- The assistant cannot modify any data — it is read-only
- Technology risk analysis and roadmap status are coming soon
- SWOT analysis and similar frameworks will be synthesized from available data (costs, assessments, technology health) rather than using a dedicated analysis tool
