---
name: tmux-handler
description: >-
  Handle incoming [CODEX] messages from Codex via tmux. Covers review completion,
  questions, task results, and plan review findings in TOON format. Triggers whenever
  a [CODEX] prefixed message appears — review complete notifications, questions from
  Codex, task completion notices, or plan review results. Use this skill to correctly
  parse, validate, triage, and respond to any Codex communication.
user-invocable: false
---

# tmux-handler — Handle incoming messages from Codex via tmux

## Trigger

You see a message in your pane prefixed with `[CODEX]`. These are from Codex's tmux pane.

## TOON findings format

Codex findings files use TOON format.

### Canonical schema

```toon
findings[N]{id,file,line,severity,category,description,suggestion}:
  F1,path/to/file.ts,42,blocking,correctness,"Description here","Suggestion here"
summary: One paragraph summary
stats:
  blocking_count: 0
  non_blocking_count: 0
  files_reviewed: 0
```

### Triage checklist

When reading a TOON findings file:
1. Validate header line matches `findings[N]{id,file,line,severity,category,description,suggestion}:`
2. Verify `[N]` equals the actual row count
3. Read `summary` and `stats` sections
4. If malformed: record validation issue, request re-emit from Codex via `--prompt`, OR triage manually as plain text if urgent

### Helper workflow

When Bash is available, prefer the shared transport helper over manual TOON parsing or emission.

Use `~/.claude/skills/codex-transport/scripts/toon-transport.sh`:

- Decode a TOON findings file to JSON:
  `~/.claude/skills/codex-transport/scripts/toon-transport.sh decode <findings_file>`
- Validate a TOON findings file:
  `~/.claude/skills/codex-transport/scripts/toon-transport.sh validate-findings <findings_file>`
- Encode canonical findings JSON to raw TOON:
  `~/.claude/skills/codex-transport/scripts/toon-transport.sh encode-findings /tmp/findings.json <findings_file>`

## Transport direction

| Agent calling | Script to use | Direction |
|---|---|---|
| Claude | `tmux-codex.sh` | Claude → Codex |
| Codex | `tmux-claude.sh` | Codex → Claude |

## Message types

### Review complete
Message: `[CODEX] Review complete. Findings at: <path>`

1. Read the FULL findings file (TOON format) with your Read tool or decode it via the helper workflow above
2. Validate per the triage checklist above (or via `validate-findings`)
3. Mark review evidence as complete:
   `tmux-codex.sh --review-complete <path>`
4. Triage each finding: blocking / non-blocking / out-of-scope
5. Update your issue ledger (reject re-raised closed findings, detect oscillation)
6. The verdict comes from the `VERDICT:` line Codex wrote in the findings file — `--review-complete` reads it automatically:
   - `VERDICT: APPROVED` in findings → approval evidence created
   - `VERDICT: REQUEST_CHANGES` → only codex-ran evidence; fix code, re-run critics, dispatch new `--review` → `--review-complete`
   - Unresolvable → `tmux-codex.sh --needs-discussion "reason"`
   - **Do NOT call `--approve` directly** — the gate blocks it.

### Question from Codex
Message: `[CODEX] Question: <question>. Write response to: <response_file>`

1. Read the question
2. Investigate the codebase to answer the question
3. **Structured findings response**: When Codex requests structured findings and provides a `.toon` response path, emit canonical TOON with the helper workflow above — not markdown tables. Codex (the requester) controls the extension; write to the exact path provided.
4. **Narrative Q&A**: When the request is conversational, write concise text to the provided path. A `.toon` extension alone does not force a structured TOON payload.
5. Notify Codex: `tmux-codex.sh --prompt "Response ready at: <response_file>" "$(pwd)"`

### Task complete
Message: `[CODEX] Task complete. Response at: <path>`

1. Read the response file. If the original request asked for structured findings, expect TOON; otherwise treat it as plain text.
2. Continue your workflow with the information Codex provided

### Plan review complete
Message: `[CODEX] Plan review complete. Findings at: <path>`

1. Read the findings file (TOON format), preferably via the helper workflow above
2. Validate per the triage checklist above
3. Triage findings same as code review (blocking / non-blocking / out-of-scope)
4. Incorporate feedback into the plan

## Dispute Resolution Protocol

When Codex or critics return findings you disagree with (out-of-scope, NEEDS_DISCUSSION), resolve between agents before escalating to the user.

### Critic disputes

Critics are your own sub-agents. When a critic flags out-of-scope code or returns NEEDS_DISCUSSION:

1. Re-run the critic with updated prompt context: include which findings are out-of-scope and why
2. The critic sees the rationale and either accepts (APPROVE) or raises new evidence
3. Max 2 dispute rounds per critic — if still unresolved, escalate to user

### Codex out-of-scope disputes

When Codex raises findings you triage as out-of-scope:

1. Write a dispute context file to `/tmp/` with dismissed findings:
   ```
   ## Dismissed Findings
   ### F2
   rationale: Out-of-scope — TASK excludes auth module changes
   ### F3
   rationale: Pre-existing code, not modified by this diff
   ```
2. Pass as 5th arg to `--review`:
   `tmux-codex.sh --review <work_dir> <base> "<title>" /tmp/dispute-context.md`
3. Codex reads the file, accepts valid dismissals (drops them), challenges invalid ones with file:line evidence
4. If challenged: evaluate the evidence — concede if valid (fix the finding), counter-argue if not
5. Max 2 dispute rounds — if unresolved, escalate to user

### Codex NEEDS_DISCUSSION

When Codex returns NEEDS_DISCUSSION:

1. Formulate your position: concede, counter-argue, or propose compromise
2. Send via `--prompt` with structured reasoning
3. Codex responds with evidence-based reasoning
4. Max 2 prompt exchanges — if unresolved, escalate to user

### After successful dispute resolution

If the dispute concludes that work should proceed, dispatch a fresh `--review` → `--review-complete` to satisfy gate evidence requirements. The debate itself does not mint approval evidence.
