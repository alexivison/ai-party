# Task 5 — Unified Party Tracker TUI

**Dependencies:** Task 3, Task 4
**Branch:** `feature/multi-agent-planning`

## Goal

Replace the two separate TUI view modes (`ViewWorker` with Codex sidebar, and `ViewMaster` with tracker) with a single unified party tracker that shows all active sessions with master→worker hierarchy, companion status inline, and supports switching between sessions. This is the largest task in the project.

## Scope Boundary

**In scope:**
- `tools/party-cli/internal/tui/model.go` — Merge `ViewWorker`/`ViewMaster` into single view; remove `CodexStatus`, `WizardSnippet`, `claudeSessionID`, `workerModeWizard`
- `tools/party-cli/internal/tui/tracker.go` — Evolve into the unified tracker showing all sessions with hierarchy
- `tools/party-cli/internal/tui/tracker_actions.go` — Update to work with all-session view
- `tools/party-cli/internal/tui/sidebar.go` — Remove (functionality absorbed into tracker's per-session detail)
- `tools/party-cli/internal/tui/sidebar_status.go` — Refactor `ReadCodexStatus()` → `ReadCompanionStatus()` using agent's `StateFileName()`
- `tools/party-cli/internal/tui/style.go` — Update labels, rename Claude-specific styles
- `tools/party-cli/internal/tui/pane.go` — Minor updates if needed
- `tools/party-cli/internal/tui/app.go` — Simplify (one model, not two modes)

**Out of scope:**
- Session lifecycle changes (Tasks 2-3, already done)
- Hook changes (Task 7)
- Picker changes (the fzf picker is separate and works independently)

## Reference Files

### Current TUI model (being replaced)

- `tools/party-cli/internal/tui/model.go` — **Read the entire file (560 lines).** Key sections:
  - Lines 18-24: `workerMode` — delete (no separate worker mode in unified tracker)
  - Lines 26-35: `ViewMode` enum — delete `ViewWorker`/`ViewMaster` distinction
  - Lines 57-63: `SessionInfo` — remove `ClaudeSessionID`, add agent-agnostic fields
  - Lines 83-109: `Model` struct — remove `CodexStatus`, `WizardSnippet`, `claudeSessionID`, `workerMode`, `workerInput`, `workerErr`. The `tracker` field becomes the main view (not conditional on master mode).
  - Lines 191-207: `sessionMsg` handling — no mode distinction needed
  - Lines 239-253: Key handling — no `workerModeWizard` branch
  - Lines 259-338: `View()` — single tracker view always (no worker/master split)
  - Lines 363-393: `renderWizardComposer()`, `updateWorkerInput()` — delete (Wizard composer moves to tracker relay action)
  - Lines 419-480: `refreshCodexStatus()`, `refreshEvidence()`, `refreshWizardSnippet()` — refactor to generic agent state refresh

### Current tracker (being evolved)

- `tools/party-cli/internal/tui/tracker.go` — **Read the entire file (524 lines).** This is the master-session tracker. It currently only shows workers of a single master. The unified tracker evolves this to show ALL sessions with hierarchy:
  - Lines 25-32: `WorkerRow` — evolve into `SessionRow` with additional fields for hierarchy
  - Lines 60-63: `TrackerModel` — add fields for all-session data, current session detail
  - Lines 79-85: `refreshWorkers()` — becomes `refreshSessions()` loading all sessions
  - Lines 270-346: `viewWorkers()` — becomes `viewSessions()` with hierarchy rendering
  - Lines 348-404: `renderWorkerRow()` — becomes `renderSessionRow()` with master/worker/solo styling

### Current tracker actions

- `tools/party-cli/internal/tui/tracker_actions.go` — **Read the entire file.** Key sections:
  - Worker fetcher implementation (`NewLiveWorkerFetcher`)
  - `ReadClaudeState()` calls — replace with agent-agnostic state reading
  - `captureWorkerSnippet()` — resolves `"claude"` role pane, must use `"primary"`

### Current sidebar (being absorbed)

- `tools/party-cli/internal/tui/sidebar.go` — **Read the entire file (172 lines).** Functions to absorb:
  - `RenderSidebar()` — companion status rendering → becomes inline section in tracker's current-session detail
  - `RenderWizardSnippet()` — companion pane snippet → same
  - `RenderEvidence()` — evidence summary → same

### Current sidebar status

- `tools/party-cli/internal/tui/sidebar_status.go` — `ReadCodexStatus()` reads `codex-status.json`. Refactor to `ReadCompanionStatus(runtimeDir, statusFileName)` accepting the agent's state file name.

### Style constants

- `tools/party-cli/internal/tui/style.go` — Labels: `LabelMaster`, `LabelWorker`, `LabelWizard`, `LabelEvidence`. `LabelWizard` → `LabelCompanion`. Claude-specific styles: `claudeStateActiveStyle` etc → `primaryStateActiveStyle`.

### Picker hierarchy (visual reference)

- `tools/party-cli/internal/picker/format.go` — Lines 78-93: `entryStyle()` function. Master = `●` gold, Worker = `│` yellow. **The unified tracker must match this visual language.**

### State discovery

- `tools/party-cli/internal/state/discovery.go` — `DiscoverSessions()` — lists all sessions from the state directory. The tracker will use this to get all sessions, not just workers of one master.

## Files to Create/Modify

| File | Action | Key Changes |
|------|--------|-------------|
| `tools/party-cli/internal/tui/model.go` | Modify (major) | Remove `ViewWorker`/`ViewMaster`; single tracker view; remove Codex/Claude-specific fields |
| `tools/party-cli/internal/tui/tracker.go` | Modify (major) | Show all sessions with hierarchy; `SessionRow` replaces `WorkerRow` |
| `tools/party-cli/internal/tui/tracker_actions.go` | Modify | Use role-based pane resolution; agent-agnostic state reading |
| `tools/party-cli/internal/tui/sidebar.go` | Modify (major) | Remove standalone rendering; companion status becomes inline in tracker detail |
| `tools/party-cli/internal/tui/sidebar_status.go` | Modify | `ReadCompanionStatus(runtimeDir, fileName)` — generic agent state reading |
| `tools/party-cli/internal/tui/style.go` | Modify | `LabelWizard` → `LabelCompanion`; rename Claude-specific style vars |
| `tools/party-cli/internal/tui/app.go` | Modify | Simplify — no mode switching needed |
| `tools/party-cli/internal/tui/pane.go` | Modify (minor) | Update if it references old role names |

## Requirements

### SessionRow (replaces WorkerRow)

```go
type SessionRow struct {
    ID              string
    Title           string
    Status          string // "active", "stopped"
    SessionType     string // "master", "worker", "standalone"
    ParentID        string // master session ID if worker
    WorkerCount     int    // number of workers if master
    PrimaryState    string // "active", "idle", "waiting", "done"
    CompanionState  string // "working", "idle", "error", "offline"
    CompanionVerdict string // "APPROVED", "REQUEST_CHANGES", etc.
    Stage           string // workflow stage label
    Snippet         string // captured primary pane output
    IsCurrent       bool   // true if this is the session the TUI is running in
}
```

### Hierarchy Display

The tracker renders sessions in a hierarchical list. Masters appear first, with their workers indented below using `│` prefix (matching picker's visual language):

```
● Project Alpha        party-1230   master (2)
│ fix-auth             party-1231   worker  ▸ ● critics ✓
│ dark-mode            party-1232   worker  ▸ ○ idle
● solo task            party-1236   active  ▸
```

Visual language (from `picker/format.go`):
- Master: `●` with gold color (`#ffd700`)
- Worker: `│` with yellow/warn color (ANSI 3)
- Standalone: `●` with green/clean color (ANSI 2)
- Stopped: `○` with muted color (ANSI 8)

The primary state dot (`▸`, `◐`, `◌`, `✔`) appears after the type badge.

### Current Session Detail Section

Below the session list, a separator and expanded detail for the current session:

```
── this session ─────────────────────
party-1230  master  ~/Code/project-b
  companion: codex (idle, APPROVED)
  evidence: code-critic ✓  minimizer ✓
```

This replaces what `RenderSidebar()` and `RenderEvidence()` currently show in the worker sidebar. The companion status is read via the agent's `StateFileName()` (or `ReadCompanionStatus()`). Evidence is read via the existing `ReadEvidenceSummary()`.

If the current session is a master, the detail also shows the master-specific info.

### Actions

Master-context actions (`r` relay, `b` broadcast, `s` spawn, `x` stop, `d` delete) only activate when the cursor is on a worker that belongs to the current master session. If the current session is not a master, these keys are disabled.

Universal actions: `j`/`k` navigate, `Enter` jump/switch, `m` manifest, `q` quit.

### Data Flow

1. On tick (3 seconds): call `DiscoverSessions()` from `state.Store` to get all sessions
2. For each session: read manifest for metadata, check tmux liveness via `Client.HasSession()`
3. Build `[]SessionRow` with hierarchy (masters first, workers grouped under their master)
4. For current session: read companion status file + evidence JSONL
5. Render

### Model Simplification

The `Model` struct simplifies to:

```go
type Model struct {
    SessionID    string       // current session (auto-discovered)
    Width, Height int
    Err          error

    // The tracker IS the view — no separate modes
    tracker      TrackerModel
    resolved     bool
    resolver     SessionResolver

    // Agent metadata for current session
    registry     *agent.Registry  // nil until resolved
}
```

Remove: `Mode`, `CodexStatus`, `Evidence`, `WizardSnippet`, `claudeSessionID`, `workerMode`, `workerInput`, `workerErr`, `checkCodexPane`.

The `TrackerModel` absorbs the companion status polling and evidence reading for the current session.

## Tests

- Tracker with no sessions → "No sessions" message
- Tracker with one standalone session → single row with `●` green
- Tracker with master + 2 workers → master row (`●` gold), two worker rows (`│` yellow, indented)
- Tracker with current session as worker → detail section shows companion status
- Tracker `Enter` on active session → `Attach()` called
- Tracker `r` on worker of current master → relay input activated
- Tracker `r` on a session that's not a worker of current master → no-op
- Companion status reading with `codex-status.json` → correct state parsed
- Companion status reading with missing file → "offline" state
- All existing tracker tests updated for new SessionRow type

## Acceptance Criteria

- [ ] `ViewWorker` and `ViewMaster` enums removed
- [ ] Single tracker view renders for all sessions
- [ ] Master→worker hierarchy displayed with `●`/`│` visual language
- [ ] Current session detail section shows companion status and evidence
- [ ] `RenderSidebar()` standalone rendering removed (absorbed into tracker)
- [ ] `ReadCodexStatus()` → generic `ReadCompanionStatus()`
- [ ] `LabelWizard` → `LabelCompanion` in style constants
- [ ] Claude-specific style names updated
- [ ] All TUI tests pass
