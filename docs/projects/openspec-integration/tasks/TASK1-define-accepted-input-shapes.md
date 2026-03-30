# Task 1 - Define Accepted Input Shapes

**Dependencies:** none | **Issue:** TBD

---

## Goal

Define the OpenSpec execution contract before any workflow logic changes. The contract should be plain: for this landing, the operator provides `change_dir + task_id`, and the harness derives scope boundaries from explicit OpenSpec artifacts rather than from a shadow TASK clone. The legacy `task_file` path stays as-is by non-change. No `mode` flag, no repo detection layer, no Bash parser library pretending to be clever.

## Scope Boundary (REQUIRED)

**In scope:**
- Document the OpenSpec execution input shape and the legacy-path non-goal
- Define the shared downstream work packet the OpenSpec path must produce
- Define the authoritative derivation order for `scope_items` and `out_of_scope`: proposal capability boundaries/exclusions, then design `Non-Goals`, then selected task heading context and task text
- State the invariants that all later tasks must preserve: one execution path, one review spine, one evidence spine

**Out of scope (handled by other tasks):**
- Implementing the OpenSpec task-workflow entry changes
- Extending `scribe` to use polymorphic requirement sources
- Gating apply/archive flows
- Changing evidence policy
- Refactoring the existing `task_file` path beyond leaving it intact

**Cross-task consistency check:**
- Tasks 2 and 3 must consume this documented OpenSpec contract rather than inventing new discriminants
- The contract must not introduce `detect_planning_mode()` or a `mode` field
- The contract must not require a shell parser for `tasks.md`
- The contract must fail closed when proposal/design do not provide enough negative scope to derive `out_of_scope`

## Reference

Files to study before implementing:

- `claude/skills/task-workflow/SKILL.md:20` - current PLAN/TASK pre-flight assumptions
- `claude/rules/execution-core.md:9` - existing single downstream execution sequence
- `claude/agents/scribe.md:21` - current TASK-only requirement extraction

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for the OpenSpec downstream work packet
- [ ] Params struct(s) for `change_dir + task_id`
- [ ] Params conversion functions from OpenSpec input to the shared work packet
- [ ] Any adapters between OpenSpec task numbering and the shared checkbox-target concept

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/rules/execution-core.md` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Create |

## Requirements

**Functionality:**
- Document the OpenSpec execution input shape and its shared downstream work packet
- Define a concrete derivation order for `scope_items` and `out_of_scope`
- Make OpenSpec handoff explicit in docs without introducing repo detection
- Preserve the existing execution-core sequence as the sole downstream path
- Preserve the current `task_file` path by non-change rather than by new convergence work

**Key gotchas:**
- Do not smuggle repo-mode detection back in under another name
- Do not replace a clear prompt contract with a Bash helper that merely re-parses Markdown
- Do not invent `out_of_scope`; if proposal/design do not yield negative boundaries, the OpenSpec path must fail closed

## Tests

Test cases:
- Docs state the OpenSpec input shape and the legacy-path non-goal clearly
- Docs define the scope derivation order from proposal/design/task context
- Docs fail closed when negative scope sources are missing
- Docs do not mention `detect_planning_mode()` or a `mode` field
- Execution-core still describes one downstream sequence

Verification commands:
- `bash claude/hooks/tests/test-openspec-routing.sh`
- `rg -n "change_dir|task_id|out_of_scope|Non-Goals|detect_planning_mode|mode" claude/skills/task-workflow/SKILL.md claude/rules/execution-core.md`

## Acceptance Criteria

- [ ] The harness documents the OpenSpec input contract, the authoritative scope-derivation order, and one downstream execution path
- [ ] No repo-mode detection layer or `mode` field is introduced
- [ ] OpenSpec handoff is explicit without creating classic runtime artifacts for OpenSpec projects
- [ ] The existing `task_file` path is explicitly left untouched in this landing
