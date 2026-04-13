---
name: wants
description: >
  Compile a WANT TO DO list by reading the user's personal Slack DM and cross-referencing
  against a local state file. Use when the user invokes `/wants`, asks "what's in my
  backlog", "check my wants", "what did I want to do", or wants to mark/ignore/annotate
  an item from their Slack notes.
---

# Wants

The user drops casual notes into their personal Slack DM about things they want to do.
This skill turns that stream into a WANT TO DO list without modifying the DM.

## Sources

- **Slack DM**: `slack_read_channel` with `channel_id: D01S7TKG3JB`, `limit: 50`,
  `response_format: detailed`. Detailed format is essential — concise strips
  `Message TS`, which is the state file's key.
- **State**: `~/.claude/wants/state.json`. Pending items are NOT in the file — absence
  means pending. Create file and parent dir on first write. Pretty-print (2-space indent).

```json
{
  "<slack_message_ts>": {
    "status": "done" | "ignored",
    "resolved_at": "<ISO 8601 UTC>",
    "note": "<optional short string>"
  }
}
```

## Operations

**List (default)** — `/wants`, "what's pending", etc.
1. Fetch DM, load state.
2. Skip any message whose ts appears in state (done or ignored — both drop out). Everything else is pending.
3. Render per format below.

**Mark done/ignored** — "mark 3 done", "ignore the Archon one", "mark 2 done: shipped in #123".
1. Resolve target: numbered ref from last rendered list, or fuzzy content match. Ask if ambiguous.
2. Write state entry with `resolved_at` = now UTC and optional `note`.

**Annotate** — notes live only on resolved items. For pending items, tell the user to
edit/reply in the Slack DM (the DM is source of truth for open items).

## Output

```
## 📝 Wants

### Pending (N)

| # | Item | Noted |
|---|------|-------|
| 1 | Try out github.com/coleam00/Archon | Apr 13 |
```

- Pending ordered newest first, 1-based numbering (session-local, regenerated each render).
- Dates as short human form (`Apr 13`) in the user's local timezone.
- Condense multi-line messages to one-line summaries; preserve bare URLs verbatim.
- Do NOT list resolved items. State is source of truth for what's closed — the user
  does not need to see it rendered back. If the user explicitly asks "what did I mark
  done" or similar, read `state.json` directly and answer ad hoc.
- If zero pending: `✨ Inbox zero — all wants handled.`

### Duplicates

After rendering the pending table, scan for near-duplicates and surface them as a
short list. Detection is loose — look for pairs/groups where the core subject word
overlaps (e.g. two messages both about "open in nvim", or two about "TOON").

```
### Possible duplicates
- #5, #6 — open in nvim to scry
- #26, #27 — TOON / handshake token weight
```

- Only show when there are actual matches. Omit the section otherwise.
- Reference items by their numbered position in the pending table, not by ts.
- Keep the hint terse — one line per cluster. The user decides what to ignore.
- Do not flag cross-section duplicates (pending vs. recently done).

## Principles

- **Never classify content.** Every Slack message appears as pending unless the user
  has explicitly `ignored` it. Let the user be the filter.
- **Read-only on Slack.** No posts, reactions, or edits.
- **Preserve unknown state keys.** The user may hand-edit `state.json`.
- **Skip bot/system messages silently** — don't number them.
