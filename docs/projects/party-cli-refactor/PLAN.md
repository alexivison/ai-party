# party-cli Refactor Plan

Deep maintainability audit of `tools/party-cli/` — 64 Go files, ~5200 LOC prod, ~8300 LOC test.

**Audited:** 2026-03-23 (full re-read of every Go file).

## Executive Summary

The codebase is surprisingly well-structured for fast-grown code. Package boundaries are clean, tests are behavioral (not implementation-coupled), and the separation of concerns between cmd/session/state/tmux/tui/message/picker is sound. The primary issues are **duplicated utility functions** across packages (5 functions with 2-3 copies each), **dead code** from iterative development (~100 lines of unused exports), and **a few complexity hotspots** in the layout/session setup paths. No architectural rewrites needed.

---

## Findings

### HIGH Severity

#### H1. Duplicated `getExtraField` / `extraString` — 3 copies
Three independent implementations of "read a string from Manifest.Extra":
- `session/service.go:89` — `getExtraField(m *state.Manifest, key string) string`
- `message/message.go:221` — `getExtraField(m *state.Manifest, key string) string` (identical)
- `picker/picker.go:241` — `extraString(m state.Manifest, key string) string` (same logic, pointer vs value receiver)

**Risk:** Divergence if one copy gets a bugfix the others don't.
**Fix:** Move to `state.Manifest` as a method: `func (m Manifest) ExtraString(key string) string`. Delete all three copies.
**Scope:** ~15 lines changed, ~30 lines deleted. Touches 4 files.

#### H2. Duplicated `nowUTC()` — 2 copies
- `session/service.go:52` — `nowUTC() string`
- `state/manifest.go:88` — `nowUTC() string`

Same format, same behavior. Both packages use it for timestamps.
**Fix:** Keep in `state` (it owns timestamp semantics). Remove from `session`, import from `state`.
**Scope:** ~5 lines changed across 2 files.

#### H3. Duplicated `sortByMtime` + `fileModTime` — 2 copies
- `cmd/list.go:114-128` — `sortByMtime` + `fileModTime`
- `picker/picker.go:271-285` — identical copies

**Fix:** Move to `state` package (it knows the manifest file layout). Both consumers import.
**Scope:** ~20 lines moved, ~20 deleted. Touches 3 files.

#### H4. `setCleanupHook` — embedded Perl/bash/jq in a Go string (layout.go → start.go:269-282)
A 6-line shell heredoc with nested Perl flock coordination, jq rewriting, and quoting gymnastics. This is the single most fragile piece of code in the codebase:
- Untestable (unit tests can't mock run-shell content)
- Shell injection risk from `sessionID` (mitigated by regex validation, but defense-in-depth says don't embed)
- Perl dependency assumption (macOS-only)

**Fix (two phases):**
1. **(This plan)** Extract the hook body into a standalone shell script `scripts/cleanup-hook.sh` that takes `$SR` and `$W` as args. The Go code generates `run-shell "scripts/cleanup-hook.sh ..."` — testable, readable, editable.
2. **(Future)** Replace the jq/Perl flock with a Go subcommand `party-cli cleanup <session-id>` that uses the existing `state.Store` locking. Eliminates Perl dep entirely.

**Scope:** Phase 1: ~40 lines changed (new script + simplified Go). Phase 2: ~80 lines (new subcommand).

### MEDIUM Severity

#### M1. Dead code: `config.Config` and `config.Load()` — never used
- `config/config.go:6-19` — `Config` struct and `Load()` function
- `config/config.go:21-26` — `envOr` helper (only used by `Load`)

Zero callers in the entire codebase. Leftover from early design.
**Fix:** Delete `config/config.go`. Keep `config/resolve.go` (actively used).
**Scope:** -27 lines. Delete 1 file.

#### M2. Dead code: `tmux.SetPaneStyle()` and `tmux.ResizePane()` — never called
- `lifecycle.go:92-99` — `SetPaneStyle` (0 callers outside tests)
- `lifecycle.go:110-117` — `ResizePane` (0 callers outside tests)

These were used during the pre-sidebar era. The resize is now done via `RunShell` with deferred `tmux resize-pane`.
**Fix:** Delete both methods and their test cases.
**Scope:** -30 lines prod, -40 lines test.

#### M3. Dead code: `tmux.SetSessionOption()` — never called outside tests
- `lifecycle.go:182-189` — only called in `lifecycle_test.go`

**Fix:** Delete method and tests.
**Scope:** -20 lines prod, -30 lines test.

#### M4. Dead code: `tmux.WorkspaceTarget()` — only used in tests
- `popup.go:23-25` — only called in `tmux_test.go`

The actual code uses inline `fmt.Sprintf("%s:%d", ...)`. Inconsistent with `CodexTarget()` which IS used.
**Fix:** Either use `WorkspaceTarget()` consistently in production code (session/layout.go, message/message.go) OR delete it. Recommend: use it consistently — it's a good abstraction.
**Scope:** ~10 line changes if adopting, or -5 lines if deleting.

#### M5. Placeholder file: `state/state.go` — contains only a package doc comment
- `state/state.go:1-3` — "Placeholder — real implementation in Task 5"

The package doc belongs on `store.go` or `manifest.go`. The file is vestigial.
**Fix:** Move the package doc to `store.go` (which is the primary file). Delete `state/state.go`.
**Scope:** -3 lines, 1 file deleted.

#### M6. `session/start.go` — double `Store.Update` on start (lines 75-98)
Two consecutive locked `Update` calls on the same manifest within `Start()`:
1. Lines 75-88: sets `last_started_at`, optional `initial_prompt`, resume IDs
2. Lines 90-95: sets `parent_session` (only if `MasterID != ""`)

These could be a single `Update` call. The double lock acquisition is wasteful and theoretically allows a race between the two writes.
**Fix:** Merge into a single `Update` call.
**Scope:** ~15 lines changed in 1 file.

#### M7. `session/continue.go` vs `session/start.go` — near-duplicate launch sequences
Both `Start()` and `Continue()` follow the same pattern:
1. Resolve binaries/paths
2. Build claude/codex commands
3. Persist resume IDs
4. Set resume env
5. Launch layout (classic/sidebar/master)
6. Set cleanup hook

`Continue()` (lines 32-127) is ~70% copy-paste of `Start()` (lines 34-153) with minor differences (cwd fallback, reading from manifest). This is the largest structural duplication.

**Fix:** Extract a shared `launchSession(ctx, sessionID, config LaunchConfig)` method that both `Start` and `Continue` call after they've resolved their respective configs. The `LaunchConfig` struct captures: cwd, winName, claudeBin, codexBin, agentPath, claudeResumeID, codexResumeID, prompt, title, master, layout.
**Scope:** ~60 lines new shared code, ~80 lines removed from continue.go + start.go. Net -20 lines.

#### M8. `filterSnippetLines` vs `filterPaneLines` — similar but not identical
- `picker/picker.go:224` — `filterPaneLines(raw string, max int) []string` — matches `❯` or `⏺` prefixes
- `tui/tracker_actions.go:130` — `filterSnippetLines(captured string, n int) string` — matches `⏺` or `❯` prefixes (same chars, different unicode escapes)

Both extract meaningful agent output lines from captured tmux pane content. The differences:
- Return type: `[]string` vs `string` (joined)
- Unicode references: literal vs `\u23fa`/`\u276f` (same characters)

**Fix:** Unify into a shared helper in a new `internal/paneutil` package (or add to `tmux`). One function, caller decides join vs slice.
**Scope:** ~20 lines.

#### M9. `session/service.go` `setExtraField` has no callers outside `session`
- `setExtraField` is unexported and only called from `start.go` and `continue.go`
- Fine as-is, but if H1 promotes `ExtraString` to a Manifest method, symmetry suggests `SetExtra(key, value string)` should live on Manifest too.

**Fix:** Add `func (m *Manifest) SetExtra(key, value string)` alongside the `ExtraString` method from H1. Delete `setExtraField` from session.
**Scope:** ~10 lines.

### LOW Severity

#### L1. Stale comment in `state/state.go`
Line 3: "Placeholder — real implementation in Task 5" — the real implementation has existed for 10+ tasks.
**Fix:** Addressed by M5 (delete file).

#### L2. Blank lines in layout functions
`layout.go:51`, `layout.go:103`, `layout.go:125-126`, `layout.go:159`, `layout.go:176-177` — scattered empty lines between `SetPaneOption` calls that don't serve readability.
**Fix:** Remove in passing during M7 refactor.

#### L3. `cmd/list.go` and `cmd/prune.go` both build `liveSet` the same way
Lines `list.go:33-38` and `prune.go:50-55` — identical `liveSet` construction loop.
**Fix:** Not worth extracting — it's 4 lines, used twice, and the contexts are different enough that a shared helper would be over-abstraction.

#### L4. `session/stop.go` — `validPartyID` regex duplicated with `state/store.go`
- `session/stop.go:10` — `var validPartyID = regexp.MustCompile('^party-[a-zA-Z0-9_-]+$')`
- `state/store.go:15` — `var validPartyID = regexp.MustCompile('^party-[a-zA-Z0-9_-]+$')`
- Also used in `session/promote.go:15` and `session/spawn.go:21` (referencing the stop.go var)

Same regex compiled independently in two packages. Both guard against invalid session IDs.
**Fix:** Export from `state`: `func IsValidPartyID(id string) bool` or `var ValidPartyID`. Session package imports.
**Scope:** ~8 lines changed across 3 files.

#### L5. `picker.Entry.SessionID` includes leading spaces for worker indentation
- `picker/picker.go:123` — `SessionID: "  " + wid`
- Data-layer field embeds display formatting. `FormatEntries` should handle indentation.
**Fix:** Add an `Indent int` or `IsChild bool` field to `Entry`. `FormatEntries` applies padding.
**Scope:** ~8 lines across picker.go and fzf.go.

#### L6. `tui/tracker_actions.go:135-136` — Unicode escapes instead of literals
- `"\u23fa"` and `"\u276f"` are `⏺` and `❯` — the picker version uses actual Unicode characters which is clearer.
**Fix:** Use literal characters or named constants.
**Scope:** 2 lines.

#### L7. Error messages use bare `fmt.Errorf` without `%w` in a few places
- `session/start.go:176` — `fmt.Errorf("failed to generate unique session ID")` — no wrapping
- `session/stop.go:17` — validation error without wrapping

These are terminal errors (not wrapping an underlying error), so `%w` isn't applicable. **No action needed.**

#### L8. `tui/model.go` uses `context.Background()` in several closures
`model.go:349-355`, `model.go:380-383` — creates fresh `context.Background()` inside Bubble Tea command closures. This is correct for BubbleTea's async pattern (commands run on a separate goroutine). **No action needed.**

#### L9. `tui/tui.go` (package doc) is a standalone doc-only file
4 lines. The convention is fine — Go tooling respects `doc.go` / package-level files. **No action needed.**

---

## What NOT to Touch

1. **The `Manifest.Extra` JSON round-trip pattern** (`manifest.go:39-85`). The marshal/unmarshal with `knownKeys` looks complex but is correct and necessary for bash interop. Do not simplify.

2. **The `acquireFlock` busy-wait pattern** (`store.go:208-220`). Looks like it could use `select`/channels, but `syscall.Flock` is the correct approach for cross-process file locking. The 10ms poll is appropriate.

3. **The `cleanClaudeCodeEnv` ignoring errors** (`start.go:228-232`). The comment explains why — best-effort unset. Correct.

4. **The `SplitWindow` variadic `pct` parameter** (`lifecycle.go:73`). Looks odd but is a clean API for optional percentage.

5. **The mock runner in `session/session_test.go`**. It's 100 lines but correctly simulates tmux state transitions. Replacing it with a mock generator would add a dependency for no gain.

6. **`dimWindowStyle` constant** (`layout.go:9`). Only used once, but it documents intent and is appropriate as a named constant.

7. **The `attachSession` function in `cmd/picker.go`** using raw `exec.Command`. The comment correctly explains why the `Client` abstraction can't handle `attach-session` (needs stdio forwarding).

---

## Task Dependency Graph

```
Phase 1 — Dead code (all parallel, no deps):
  M1 (delete config.Config)
  M2 (delete SetPaneStyle/ResizePane)
  M3 (delete SetSessionOption)
  M5 (delete state.go placeholder)

Phase 2 — Dedup (all parallel, no deps between them):
  H1 (ExtraString method on Manifest)
  H2 (nowUTC → state only)
  H3 (sortByMtime → state)
  L4 (validPartyID → state.IsValidPartyID)
  M8 (unify filterLines)

Phase 3 — API cleanup (deps on Phase 2):
  M4 (adopt WorkspaceTarget) — independent
  M9 (SetExtra on Manifest) — depends on H1

Phase 4 — Session consolidation (deps on Phase 2+3):
  M6 (merge double Update in Start) — depends on M9
  M7 (unify Start/Continue launch) — depends on M6, H1, H2

Phase 5 — Cleanup hook (independent, high risk, do last):
  H4 (extract cleanup hook to script/subcommand)
```

## Recommended Execution Order

| Phase | Tasks | Scope | Risk |
|-------|-------|-------|------|
| 1. Dead code removal | M1, M2, M3, M5 | -100 lines | None |
| 2. Utility dedup | H1, H2, H3, L4, M8 | ~50 lines net | Low (mechanical moves) |
| 3. API cleanup | M4, M9 | ~20 lines | Low |
| 4. Session consolidation | M6, M7 | ~80 lines net reduction | Medium (Start/Continue are critical paths) |
| 5. Cleanup hook | H4 phase 1 | ~40 lines | Medium (tmux hook is production-critical) |

**Total estimated net change:** -130 lines (from ~5200 to ~5070). The value is not in line count but in reducing the number of places that need to change when fixing bugs.

---

## Verification Strategy

- Run `go test ./...` after each phase
- Run `golangci-lint run` after each phase
- Manual smoke test after Phase 4 and 5 (start, continue, promote, spawn a session)
- Phase 5 specifically needs a stop/restart cycle to verify the cleanup hook fires correctly
