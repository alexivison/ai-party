# OpenSpec Integration Into The Claude Code Harness Implementation Plan

> **Goal:** Let the next feature project use stock OpenSpec artifacts as the planning truth while preserving the harness's existing execution, evidence, review, and PR-gate protections.
>
> **Architecture:** The harness keeps one downstream execution path. `task-workflow` accepts one of two explicit input shapes at the entry seam: a classic `task_file`, or an OpenSpec `change_dir + task_id`. That entry step assembles the same work packet for critics, Codex, evidence, and PR gating. No repo-mode detection layer, no threaded `if openspec` branches, and no shell parser for Markdown.
>
> **Tech Stack:** Markdown workflow specs, Bash hooks, `jq`, `git`, JSONL evidence, OpenSpec artifact layout
>
> **Specification:** [SPEC.md](./SPEC.md) | **Design:** [DESIGN.md](./DESIGN.md)

## Scope

This plan covers the harness seams that presently assume classic planning artifacts: `claude/skills/task-workflow/SKILL.md`, `claude/skills/plan-workflow/SKILL.md`, `claude/agents/scribe.md`, `claude/rules/execution-core.md`, `claude/hooks/pr-gate.sh`, `claude/hooks/lib/evidence.sh`, and `claude/settings.json`.

Track 1 is the must-have path for the next OpenSpec project:
- OpenSpec owns planning artifacts.
- `task-workflow` accepts explicit OpenSpec execution input: `change_dir + task_id`.
- `scribe` audits against proposal + specs + design + selected task.
- apply/archive are routed through harness-safe entrypoints.

The classic path remains supported for now through explicit `task_file` input. That path is preserved because it converges cleanly into the same downstream execution flow. If later implementation proves even this entry-seam polymorphism uglier than retiring classic assumptions outright, the harness may remove the classic-only path then, but not before the simpler approach is tested honestly.

Out of scope:
- rewriting OpenSpec itself
- replacing the existing critic/Codex/evidence/PR-gate spine
- adding repo-mode detection or `mode` flags across workflows

## Task Granularity

- [x] **Standard** - each task owns one harness seam or one gate/policy slice and should fit a normal PR
- [ ] **Atomic** - not used; the risk lies in contract boundaries, not minute-by-minute edits

## Tasks

### Track 1 - Unified Execution Path

- [ ] [Task 1](./tasks/TASK1-define-accepted-input-shapes.md) - Define the accepted planning input shapes and handoff rules so skills converge on one downstream execution path without mode detection (deps: none)
- [ ] [Task 2](./tasks/TASK2-adapt-task-workflow-input-shapes.md) - Teach `task-workflow` to accept either a TASK file or an OpenSpec change/task reference, with branching localized to the entry seam only (deps: Task 1)
- [ ] [Task 3](./tasks/TASK3-teach-scribe-polymorphic-requirement-sources.md) - Teach `scribe` to audit either a TASK file or an OpenSpec artifact bundle via one `requirement_sources` contract (deps: Task 1)
- [ ] [Task 4](./tasks/TASK4-gate-openspec-apply-and-archive.md) - Add harness-safe OpenSpec wrappers and an archive gate so execution and archival cannot bypass the existing evidence spine (deps: Task 2, Task 3)

### Follow-On Policy Work

- [ ] [Task 5](./tasks/TASK5-finalize-metadata-and-evidence-policy.md) - Decide optional task metadata and `openspec/**/*.md` diff-hash policy, then codify the final routing/docs rules around the unified input-shape design (deps: Task 4)

## Coverage Matrix

| New Field/Endpoint | Added In | Code Paths Affected | Handled By | Converter Functions |
|--------------------|----------|---------------------|------------|---------------------|
| Accepted task input shapes: `task_file` or `change_dir + task_id` | Task 1 | plan-workflow docs, task-workflow entry, execution handoff guidance | Tasks 2, 4 | Entry-shape parsing into a shared work packet |
| Selected task scope packet (`task text`, heading path, checkbox target, scope notes) | Task 2 | task-workflow, critics, Codex, sentinel, completion updates | Tasks 2, 3, 4 | `task_file` or OpenSpec task reference -> scope packet |
| `requirement_sources` contract | Task 3 | scribe audit, implementation mapping, test mapping | Tasks 3, 4 | TASK file or OpenSpec bundle -> numbered requirement ledger |
| Archive allow/deny decision | Task 4 | archive wrapper, completion gate, operator feedback | Tasks 4, 5 | `archive_gate()` using existing evidence readers |
| Optional metadata and markdown evidence policy | Task 5 | OpenSpec docs, evidence hash, docs-only gate behavior | Task 5 | Optional metadata parser + `compute_diff_hash()` policy updates |

**Validation:** Stock OpenSpec artifacts remain the primary planning truth. Any metadata extension in Task 5 must remain optional and backward-compatible.

## Dependency Graph

```text
Task 1 ───┬───> Task 2 ───┐
          │               ├───> Task 4 ───> Task 5
          └───> Task 3 ───┘
```

## Task Handoff State

| After Task | State |
|------------|-------|
| Task 1 | The harness documents two accepted input shapes and one downstream execution path, with no mode flag or repo detection layer |
| Task 2 | `task-workflow` can execute either a classic TASK file or an OpenSpec change/task reference |
| Task 3 | `scribe` can audit either a TASK file or an OpenSpec artifact bundle through one `requirement_sources` contract |
| Task 4 | OpenSpec execution/archive routes can no longer bypass the harness completion spine |
| Task 5 | Metadata and evidence policy are explicit, tested, and documented |

## External Dependencies

| Dependency | Status | Blocking |
|------------|--------|----------|
| OpenSpec change layout under `openspec/changes/<slug>/` | Fixed upstream contract | Tasks 1-5 |
| Existing execution-core and PR-gate semantics | Fixed internal contract | Tasks 2-5 |
| Current hook surface in `claude/settings.json` | Fixed constraint | Task 4 |
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
- `claude/settings.json:84-164` only exposes Bash and Skill hook matchers. Therefore Task 4 still uses wrappers and downstream gate enforcement rather than promising impossible interception of every third-party slash command.

## Definition of Done

- [ ] All task checkboxes complete
- [ ] A stock OpenSpec change can be executed through the harness via explicit `change_dir + task_id` input without creating classic runtime artifacts in the target project
- [ ] Classic work can still be executed through explicit `task_file` input while that path remains supported
- [ ] `scribe`, critics, Codex, and PR gate receive equivalent scope and completion context from either accepted input shape
- [ ] OpenSpec apply/archive routes cannot bypass the harness execution spine
- [ ] Metadata and evidence policy are explicit and covered by regression tests
