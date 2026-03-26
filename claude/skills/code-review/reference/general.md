# Code Review Reference

Rules for reviewing code changes. Use `[must]`, `[q]`, `[nit]` labels.

---

## Severity Labels

| Label | Meaning | Blocks |
|-------|---------|--------|
| `[must]` | Bugs, security, maintainability violations | Yes |
| `[q]` | Clarification or justification request | No |
| `[nit]` | Style, minor suggestions | No |

---

## Maintainability Thresholds

### Blocking `[must]`

| Issue | Threshold |
|-------|-----------|
| Function length | >50 lines |
| Nesting depth | >4 levels |
| Parameters | >5 |
| Duplicate code | >5 lines repeated (or >3 lines repeated 3+ times) |
| Magic numbers/strings | Literals used 2+ times without a named constant |
| Inline complex conditionals | Compound boolean expressions (3+ clauses) not extracted to a named variable |

### Warning `[q]`

| Issue | Threshold |
|-------|-----------|
| Function length | >30 lines |
| Nesting depth | >3 levels |
| Parameters | >4 |
| Unnamed numeric literals | Any non-obvious number (not 0, 1, -1) without a named constant |
| String literal reuse | Same string literal used 2+ times in a file |

### Complexity Delta Rule

Any change that **degrades** maintainability is `[must]`:
- Readable function becomes hard to follow
- Nesting increases significantly
- New code smell introduced

Regressions block even if absolute values are acceptable.

---

## Quality Checklist

| Check | Severity if violated |
|-------|---------------------|
| Naming: unclear or misleading | `[q]` |
| Naming: single letters (except loop index) | `[q]` |
| Tests missing for new code | `[must]` |
| Tests missing for bug fix | `[must]` |
| Comments: outdated or misleading | `[must]` |
| Comments: missing on non-obvious logic | `[q]` |
| YAGNI: unnecessary features/complexity | `[q]` |
| DRY: repeated code/string/number patterns | `[must]` |
| Magic values: unexplained literals | `[q]` |
| God function: does multiple unrelated things | `[must]` |
| Style guide violation | `[nit]` |

---

## Feature Flags

| Check | Severity |
|-------|----------|
| Flag OFF breaks existing behavior | `[must]` |
| Only one path tested | `[must]` |
| Dead code after rollout | `[q]` |

---

## Verdicts

| Verdict | Condition |
|---------|-----------|
| **APPROVE** | No `[must]` findings |
| **REQUEST_CHANGES** | Has one or more `[must]` findings |
| **NEEDS_DISCUSSION** | Architectural concerns, unclear requirements |
