# Daily Sync Template

## Slack Message Format

```
*Daily Sync — <Month Day> (<Weekday>)*

*What I wrought:*
• <ticket-link>: <description>

*What I pursue today:*
• <ticket-link>: <description>

*Blockers:*
• <description or "None">

*Notes:*
• <OOO/AFK from calendar, meeting-heavy warnings, or other context>
```

- Do NOT include a "Sent using Claude" footer — Slack adds this automatically.
- Omit the *Notes* section entirely if there's nothing to surface (no OOO, no calendar notes).

## Ticket Link Format

Every ticket ID must be a clickable Slack link using the Linear workspace URL
from `data-sources.md`. Format:
```
<https://linear.app/<workspace>/issue/PROJ-XXX|PROJ-XXX>
```

Example:
```
<https://linear.app/<workspace>/issue/PROJ-525|PROJ-525>: Reusable UI components — done
```

When two tickets share the same line (e.g., worked on together in one PR):
```
<link|PROJ-8> / <link|PROJ-41>: Description
```

Read the Linear workspace slug from `data-sources.md` to construct the URLs.

## Tone Guide

Lightly playful — a colleague should smile, not squint.

| Standard | Playful alternative |
|----------|-------------------|
| What I did | What I wrought |
| What I'm doing | What I pursue today |
| Blockers | Blockers (keep as-is) |
| completed | vanquished, sealed, done |
| working on | forging, wiring, pursuing |
| waiting for | awaiting |
| started | began the craft |
| depends on | once X is sealed / lands |

Don't force it — use plain language when the playful version sounds awkward.

## Brevity (hard rule)

Daily sync bullets must be **to the point**. Each bullet is a single short clause, not a paragraph.

- Each bullet ≤ ~15 words after the ticket link. If it reads like prose, cut.
- One clause per bullet. No sub-context, no caveats, no "need to sync with X first", no research-doc status, no piling PR numbers.
- No explanatory asides in parens unless ≤ 4 words and load-bearing.
- Draft, then cut. Context belongs in the Linear ticket or a thread reply, not the standup bullet.

**Bad:**
> NEXT-632: Begin the chat richification journey — Track A (render the `command_*` / `turn_completed` / `skill_output` events the backend already emits). Pre-spec research doc is finalized; need to sync with Nauman on ownership before claiming

**Good:**
> NEXT-632: Start chat richification (Track A — render command/turn/skill events)

## Section Guidelines

**What I wrought:**
- Only work that's actually done (merged, completed, delivered)
- Group related tickets on one line when they shipped together
- Ticket link + colon + short verb phrase. Stop there.

**What I pursue today:**
- Today's plan, one short clause per bullet
- Skip readiness context unless a teammate has to act on it

**Blockers:**
- Concrete blockers only — not "nice to haves"
- Include who/what you're waiting on
- "None" is a valid answer — no hedging

**Notes:** (optional — omit if empty)
- OOO/AFK blocks from Google Calendar (e.g., "AFK ~9:30–11:30, commuting to office")
- Meeting-heavy day warnings
- Other relevant context (team events, etc.)

## Channel

Post to the **sync target** channel configured in `data-sources.md`.
