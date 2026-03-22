# Task 9 — Launch Party CLI Pane And Sidebar Layouts

**Dependencies:** Task 6, Task 7, Task 8 | **Issue:** TBD

---

## Goal

Put the unified binary into live sessions. Pane `0` should now run `party-cli`, master sessions should show the tracker shell, worker and standalone sessions should support the sidebar shell as an opt-in layout (`PARTY_LAYOUT=sidebar`), Codex should move to a hidden deterministic companion session when sidebar mode is active, and `PARTY_LAYOUT=classic` must remain the default until Task 10 proves sidebar-mode promotion works.

## Scope Boundary (REQUIRED)

**In scope:**
- Update shell launchers to start `party-cli` in pane `0`
- Keep master layout as tracker | claude | shell
- Change standard/worker default layout to sidebar | claude | shell
- Create and clean up deterministic hidden Codex companion sessions for sidebar mode
- Preserve `PARTY_LAYOUT=classic` as a first-class escape hatch
- Update shell routing helpers so retained Codex transport resolves the companion session when sidebar mode is active
- Add a shared `party_canonical_session()` helper in `party-lib.sh` that strips the `-codex` suffix from companion session names, so all state-path calculations, manifest writes, and pane lookups resolve to the parent session
- Update `tmux-claude.sh` return-path routing to use `party_canonical_session()` so Codex-to-Claude delivery, `codex_thread_id` writes, and `party_state_set_field` calls target the parent session — not the companion
- Update `tmux-codex.sh` to use `party_canonical_session()` when resolving state paths from a companion context
- Update bash discovery paths (`party.sh --switch`, `party.sh --list`, `party-picker.sh`) to exclude `*-codex` companion sessions, since Go replacements (Task 15) are not yet live

**Out of scope (handled by other tasks):**
- Final worker sidebar widgets
- CLI lifecycle command ownership
- Final wrapper cutover

**Cross-task consistency check:**
- Companion naming created here must match the discovery filters from Task 5 and companion helpers from Task 6
- Task 12 assumes the sidebar shell launched here already exists and can read runtime status later

## Reference

Files to study before implementing:

- `session/party.sh` — current standard/worker launch flow
- `session/party-master.sh` — current master launch flow
- `session/party-lib.sh` — role routing and session discovery helpers
- `claude/skills/codex-transport/scripts/tmux-codex.sh` — retained shell caller that must keep working
- `codex/skills/claude-transport/scripts/tmux-claude.sh` — Codex→Claude return path that must resolve the parent session from companion context

## Design References (REQUIRED for UI/component tasks)

- `../diagrams/session-layouts.svg`
- `../diagrams/before-after.svg`

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A unless a typed file contract is introduced)
- [ ] Proto -> Domain converter (N/A unless a typed file contract is introduced)
- [ ] Domain model struct
- [ ] Params struct(s) — check ALL variants
- [ ] Params conversion functions
- [ ] Any adapters between param types

## Files to Create/Modify

| File | Action |
|------|--------|
| `session/party.sh` | Modify |
| `session/party-master.sh` | Modify |
| `session/party-lib.sh` | Modify |
| `claude/skills/codex-transport/scripts/tmux-codex.sh` | Modify only if helper names or routing glue change |
| `codex/skills/claude-transport/scripts/tmux-claude.sh` | Modify — add parent-session canonicalization for companion context |
| `session/party-picker.sh` | Modify — exclude `*-codex` companion sessions from scan |
| `tests/test-party-routing.sh` | Modify |
| `tests/test-party-master.sh` | Modify |
| `tests/test-party-sidebar-layout.sh` | Create |

## Requirements

**Functionality:**
- New sessions launch `party-cli` in pane `0`
- Worker and standalone sessions default to sidebar layout with hidden Codex companion
- Master sessions default to tracker layout
- `PARTY_LAYOUT=classic` preserves the existing visible-Codex behavior
- Companion sessions are cleaned up on teardown and remain hidden from user-facing discovery
- Retained Codex transport continues to resolve a live target in both sidebar and classic modes
- The session-closed hook must kill the companion Codex session on teardown via `tmux kill-session -t "${session}-codex" 2>/dev/null`

**Key gotchas:**
- Do not add a new persisted manifest field merely to track the companion; deterministic naming is sufficient
- Promotion and teardown paths must not orphan companion sessions
- Crash or force-kill of the parent session may skip the session-closed hook; prune (Task 8) serves as the orphan sweep for this case
- **Promotion compatibility (deferred to Task 10):** The current shell promotion path (`session/party-master.sh:126-133`) resolves a visible `codex` role pane. Once sidebar mode removes it, promotion would break. Task 9 does NOT fix promotion — it defers to Task 10, which owns all lifecycle commands including `promote`. Task 9 MUST NOT break the classic promotion path: sidebar mode is additive, `PARTY_LAYOUT=classic` remains the default until Task 10 proves promotion works in sidebar mode. No independently shippable PR may leave classic promotion broken.

## Tests

Test cases:
- Sidebar opt-in launch for standalone and worker sessions (`PARTY_LAYOUT=sidebar`)
- Classic default launch (no env var or `PARTY_LAYOUT=classic`)
- Master launch remains tracker-based
- Companion cleanup on stop/delete/session close
- Codex transport routing resolves the companion when sidebar mode is active
- `party_canonical_session()` strips `-codex` suffix correctly; returns input unchanged for non-companion sessions
- Codex→Claude return path (`tmux-claude.sh`) resolves the parent session via `party_canonical_session()` — state writes (`codex_thread_id`, `party_state_set_field`) target the parent, not the companion
- Bash discovery paths (`--switch`, `--list`, picker) exclude `*-codex` companions
- Orphan prevention: companion is killed even on unclean parent session death

## Acceptance Criteria

- [ ] Pane `0` launches `party-cli` in new sessions
- [ ] Sidebar and classic layouts both work as designed
- [ ] Hidden Codex companions are deterministic, hidden, and cleaned up
- [ ] `tmux-codex.sh` still reaches Codex through retained shell routing
- [ ] `tmux-claude.sh` return path works from companion session context
- [ ] Bash switch/list/picker exclude companion sessions
- [ ] Shell promotion (`party.sh --promote`) continues to work in classic mode (sidebar promotion deferred to Task 10)
- [ ] Layout and routing tests pass
