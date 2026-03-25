# Clean Code Standards

These rules apply when **writing** code — not just reviewing. Follow these proactively during implementation.

## DRY — Don't Repeat Yourself

- **String literals** used 2+ times → extract to a named constant
- **Numeric literals** (other than 0, 1, -1) → extract to a named constant with a descriptive name
- **Code blocks** repeated 2+ times (even 3-5 lines) → extract to a helper function
- **Conditionals** checking the same compound expression in multiple places → extract to a well-named boolean variable or predicate function
- **Object shapes / config patterns** duplicated across call sites → extract to a shared builder or factory

## Function Design

- **One job per function.** If you need "and" to describe what a function does, split it.
- **Target 20-30 lines.** Under 50 is mandatory (see code-review thresholds), but aim for 20-30 as the sweet spot.
- **Max 3 levels of nesting.** Flatten with early returns, guard clauses, or extraction.
- **Max 3-4 parameters.** Group related parameters into an options object / struct / dataclass when exceeding this.
- **Name functions by what they return or do**, not how: `getUserPermissions` not `queryDatabaseAndFilterResults`.

## Variables and Constants

- **Name by meaning, not by type:** `maxRetries` not `num3`, `apiBaseUrl` not `urlString`.
- **Extract complex expressions** into named intermediate variables for readability:
  ```
  // Bad
  if (user.role === 'admin' && user.org.plan === 'enterprise' && !user.suspended) { ... }

  // Good
  const isActiveEnterpriseAdmin = user.role === 'admin' && user.org.plan === 'enterprise' && !user.suspended;
  if (isActiveEnterpriseAdmin) { ... }
  ```
- **No magic values.** Every literal that isn't self-evident needs a named constant:
  ```
  // Bad
  setTimeout(fn, 86400000);

  // Good
  const ONE_DAY_MS = 86_400_000;
  setTimeout(fn, ONE_DAY_MS);
  ```

## Structure

- **Early returns** over nested if/else chains.
- **Consistent patterns** — if three similar operations exist, they should look the same structurally.
- **Collocate related logic.** Don't scatter pieces of one feature across distant parts of a file.
- **Imports at top, exports at bottom, logic in between.** Keep file structure predictable.

## When Writing New Code

Before moving on from any function or block, self-check:
1. Are there any repeated string/number literals? → Extract.
2. Is this function doing more than one thing? → Split.
3. Could someone understand this without reading surrounding code? → If not, rename or restructure.
4. Are there magic values? → Name them.
