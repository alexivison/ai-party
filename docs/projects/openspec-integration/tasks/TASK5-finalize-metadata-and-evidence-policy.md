# Task 5 - Finalize Metadata And Evidence Policy

**Dependencies:** Task 4 | **Issue:** TBD

---

## Goal

Close the remaining policy gaps after the unified input-shape design works. This is where we decide whether stock OpenSpec task text is sufficient and whether Markdown planning edits should remain invisible to diff-hash gating.

## Scope Boundary (REQUIRED)

**In scope:**
- Decide whether Track 1's stock `tasks.md` usage is sufficient or whether an optional metadata extension is warranted
- Decide and codify the `openspec/**/*.md` diff-hash policy
- Extend regression tests and workflow docs around the unified input-shape design
- Document the final operator rules for feature planning, bugfixes, and quick fixes, including that OpenSpec `party-dispatch` support remains a follow-up

**Out of scope (handled by other tasks):**
- Reworking the core execution sequence
- Replacing OpenSpec's artifact layout
- Reintroducing repo-mode detection under another name

**Cross-task consistency check:**
- If metadata is added, it must be optional; Track 1's stock OpenSpec path must remain valid
- Evidence-policy changes must not silently weaken PR-gate behavior for code changes

## Reference

Files to study before implementing:

- `claude/hooks/lib/evidence.sh:99` - current Markdown exclusion policy
- `claude/hooks/pr-gate.sh:33` - current docs-only PR bypass
- `claude/skills/bugfix-workflow/SKILL.md:18` - current bugfix routing assumptions
- `claude/skills/quick-fix-workflow/SKILL.md:27` - current non-feature shortcut rules
- `claude/rules/execution-core.md:44` - evidence freshness contract

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for optional task metadata, if introduced
- [ ] Params struct(s) for evidence-policy toggles or parser options
- [ ] Params conversion functions from Markdown planning changes to diff-hash inclusion/exclusion rules
- [ ] Any adapters between docs-only PR detection and OpenSpec planning-file changes

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/hooks/lib/evidence.sh` | Modify |
| `claude/hooks/tests/test-evidence.sh` | Modify |
| `claude/hooks/tests/test-pr-gate.sh` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Modify |
| `claude/skills/plan-workflow/SKILL.md` | Modify |
| `claude/skills/bugfix-workflow/SKILL.md` | Modify |
| `claude/skills/quick-fix-workflow/SKILL.md` | Modify |
| `claude/rules/execution-core.md` | Modify |

## Requirements

**Functionality:**
- The harness has an explicit yes/no rule for whether OpenSpec Markdown edits affect diff-hash gating
- If optional task metadata is introduced, stock OpenSpec files still parse and execute correctly
- Docs state which workflow to use for OpenSpec feature work, classic feature work, bugfixes, and quick fixes without invoking repo detection, and they note that OpenSpec worker dispatch is not part of Track 1
- Regression tests cover planning-only Markdown changes and mixed code-plus-OpenSpec changes

**Key gotchas:**
- Changing diff-hash policy can invalidate long-standing evidence behavior; test the edge cases instead of trusting instinct
- Do not let an optional metadata idea grow into a de facto second planning schema

## Tests

Test cases:
- Planning-only OpenSpec Markdown changes behave exactly as the chosen evidence policy says they should
- Mixed code + OpenSpec planning edits still require the normal full evidence spine
- Optional metadata, if present, is parsed; if absent, stock OpenSpec still works
- Docs-only PR bypass remains correct after OpenSpec-specific cases are added

Verification commands:
- `bash claude/hooks/tests/test-evidence.sh`
- `bash claude/hooks/tests/test-pr-gate.sh`
- `bash claude/hooks/tests/test-openspec-routing.sh`

## Acceptance Criteria

- [ ] Metadata policy is explicit, optional, and backward-compatible
- [ ] Evidence policy for OpenSpec Markdown changes is explicit and regression-tested
- [ ] Final docs make feature-planning, bugfix, and quick-fix routing unambiguous without repo detection
