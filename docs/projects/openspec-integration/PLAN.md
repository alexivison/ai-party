# OpenSpec Integration Into The Claude Code Harness Implementation Plan

> **Goal:** Let the next feature project use stock OpenSpec artifacts as the planning truth while preserving the harness's existing execution, evidence, review, and PR-gate protections.
>
> **Architecture:** Track 1 is OpenSpec-first. The existing classic `task_file` path stays in place as legacy behavior; the new work adds an OpenSpec entry adapter in `task-workflow` for `change_dir + task_id`, derives scope boundaries from proposal capability boundaries/exclusions, design `Non-Goals`, and selected task heading context, then hands the same work packet to critics, Codex, evidence, and PR gating. No repo-mode detection layer, no threaded `if openspec` branches, and no shell parser for Markdown.
>
> **Tech Stack:** Markdown workflow specs, Bash hooks, `jq`, `git`, JSONL evidence, OpenSpec artifact layout
>
> **Specification:** [SPEC.md](./SPEC.md) | **Design:** [DESIGN.md](./DESIGN.md)

## Scope

This plan covers the OpenSpec-first seams required for the next feature project: `claude/skills/task-workflow/SKILL.md`, `claude/agents/scribe.md`, `claude/rules/execution-core.md`, `claude/hooks/pr-gate.sh`, `claude/hooks/lib/evidence.sh`, and `claude/settings.json`. The existing classic `task_file` path remains in place as legacy behavior and is not a Track 1 refactor target.

Track 1 is the must-have path for the next OpenSpec project:
- OpenSpec owns planning artifacts.
- `task-workflow` accepts explicit OpenSpec execution input: `change_dir + task_id`.
- OpenSpec scope boundaries are derived in a fixed order: proposal capability boundaries/exclusions, then design `Non-Goals`, then selected task heading context and task text.
- `scribe` audits against proposal + specs + design + selected task.
- archive-gate requires merged-PR proof plus fresh harness evidence.

The classic path remains preserved by non-change. Track 1 does not spend effort re-plumbing or re-proving `task_file` execution through a new shared adapter; it already works today. If later implementation proves the legacy path should be converged or retired, that shall be a separate decision after the OpenSpec path succeeds in real use.

Out of scope:
- rewriting OpenSpec itself
- replacing the existing critic/Codex/evidence/PR-gate spine
- adding repo-mode detection or `mode` flags across workflows
- adding OpenSpec support to `party-dispatch` in this first landing
- refactoring the legacy `task_file` path beyond keeping it intact

## Task Granularity

- [x] **Standard** - each task owns one harness seam or one gate/policy slice and should fit a normal PR
- [ ] **Atomic** - not used; the risk lies in contract boundaries, not minute-by-minute edits

## Tasks

### Track 1 - OpenSpec-First Execution Path

- [ ] [Task 1](./tasks/TASK1-define-accepted-input-shapes.md) - Define the OpenSpec execution input contract and the authoritative scope-derivation order so the harness can build a work packet without mode detection or shadow artifacts (deps: none)
- [ ] [Task 2](./tasks/TASK2-adapt-task-workflow-input-shapes.md) - Teach `task-workflow` the OpenSpec `change_dir + task_id` entry adapter and scope packet while leaving the legacy `task_file` path untouched (deps: Task 1)
- [ ] [Task 3](./tasks/TASK3-teach-scribe-polymorphic-requirement-sources.md) - Teach `scribe` to audit an OpenSpec artifact bundle via one `requirement_sources` contract while preserving its current TASK-file output shape (deps: Task 1)
- [ ] [Task 4](./tasks/TASK4-gate-openspec-apply-and-archive.md) - Add an archive gate and honest wrapper guidance so archive requires merged-PR completion proof and the blessed OpenSpec path runs through the harness (deps: Task 2, Task 3)

### Follow-On Policy Work

- [ ] [Task 5](./tasks/TASK5-finalize-metadata-and-evidence-policy.md) - Decide optional task metadata and `openspec/**/*.md` diff-hash policy, then codify the final routing/docs rules around the unified input-shape design (deps: Task 4)

## Coverage Matrix

| New Field/Endpoint | Added In | Code Paths Affected | Handled By | Converter Functions |
|--------------------|----------|---------------------|------------|---------------------|
| OpenSpec execution input: `change_dir + task_id` | Task 1 | task-workflow entry, execution handoff guidance | Tasks 2, 4 | OpenSpec invocation -> shared work packet |
| OpenSpec scope-derivation contract (`scope_items`, `out_of_scope`, `checkbox_target`) | Task 1 | task-workflow, critics, Codex, sentinel, completion updates | Tasks 1, 2, 3 | proposal capability boundaries/exclusions + design `Non-Goals` + selected task heading path/text -> scope packet |
| `requirement_sources` contract | Task 3 | scribe audit, implementation mapping, test mapping | Tasks 3, 4 | OpenSpec bundle -> numbered requirement ledger; TASK-file path remains existing behavior |
| Archive allow/deny decision with terminal completion proof | Task 4 | archive wrapper, completion gate, operator feedback | Tasks 4, 5 | `archive_gate()` using merged-PR lookup + existing evidence readers |
| Optional metadata and markdown evidence policy | Task 5 | OpenSpec docs, evidence hash, docs-only gate behavior | Task 5 | Optional metadata parser + `compute_diff_hash()` policy updates |

**Validation:** Stock OpenSpec artifacts remain the primary planning truth. Any metadata extension in Task 5 must remain optional and backward-compatible. The legacy `task_file` flow is preserved by non-change in Track 1.

## Dependency Graph

```text
Task 1 ───┬───> Task 2 ───┐
          │               ├───> Task 4 ───> Task 5
          └───> Task 3 ───┘
```

## Task Handoff State

| After Task | State |
|------------|-------|
| Task 1 | The harness documents the OpenSpec input contract, the authoritative scope-derivation order, and fail-closed rules, while explicitly leaving the legacy `task_file` path untouched |
| Task 2 | `task-workflow` can execute an OpenSpec change/task reference and derive a deterministic scope packet from the documented artifact sources |
| Task 3 | `scribe` can audit an OpenSpec artifact bundle through one `requirement_sources` contract while preserving its current output shape |
| Task 4 | Archive now requires merged-PR completion proof plus fresh evidence, and the docs expose a blessed OpenSpec path with explicit unsupported-path warnings |
| Task 5 | Metadata and evidence policy are explicit, tested, and documented |

## External Dependencies

| Dependency | Status | Blocking |
|------------|--------|----------|
| OpenSpec change layout under `openspec/changes/<slug>/` | Fixed upstream contract | Tasks 1-5 |
| Existing execution-core and PR-gate semantics | Fixed internal contract | Tasks 2-5 |
| Current hook surface in `claude/settings.json` | Fixed constraint | Task 4 |
| GitHub CLI auth for merged-PR lookup in archive-gate | Existing repo/tooling dependency | Task 4 |
| Markdown diff-hash exclusion in `claude/hooks/lib/evidence.sh:100` | Existing policy, decision pending | Task 5 |

## Plan Evaluation Record

PLAN_EVALUATION_VERDICT: PASS

Evidence:
- [x] Existing standards referenced with concrete paths
- [x] Data transformation points mapped
- [x] Tasks have explicit scope boundaries
- [x] Dependencies and verification commands listed per task
- [x] Requirements reconciled against source inputs
- [x] Whole-architecture coherence evaluated
- [x] UI/component tasks include design references

Source reconciliation:
- This planning effort itself still uses the canonical PLAN/TASK templates because the user explicitly required them, even though the runtime design now converges on explicit input shapes rather than classic plan files.
- The revised design removes `detect_planning_mode()` and the `mode` field entirely. The operator's input shape is the only discriminant.
- The revised Task 1 removes the proposed `openspec.sh` Bash parser library. Claude already reads Markdown natively; the useful contract is the accepted inputs, not a shell parser.
- `claude/settings.json:84-164` only exposes Bash and Skill hook matchers. Therefore Task 4 documents a blessed supported path, gates archive, and marks stock `/opsx:apply` unsupported rather than promising impossible interception of every third-party slash command.
- `party-dispatch` still emits TASK-file prompts today, so OpenSpec worker dispatch is explicitly deferred to a follow-up instead of smuggled into this first landing.

## Definition of Done

- [ ] All task checkboxes complete
- [ ] A stock OpenSpec change can be executed through the harness via explicit `change_dir + task_id` input without creating classic runtime artifacts in the target project
- [ ] OpenSpec scope boundaries are derived deterministically from proposal capability boundaries/exclusions, design `Non-Goals`, and selected task context, with fail-closed behavior when those sources are missing
- [ ] The existing classic `task_file` path remains untouched; this landing does not refactor it
- [ ] `scribe`, critics, Codex, and PR gate receive the required scope and completion context for the OpenSpec path
- [ ] The harness documents one blessed OpenSpec execution path; stock `/opsx:apply` is marked unsupported and the residual bypass risk is explicit
- [ ] OpenSpec archive requires terminal completion proof (merged PR) plus fresh harness evidence
- [ ] Metadata and evidence policy are explicit and covered by regression tests
