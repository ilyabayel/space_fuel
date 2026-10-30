---
name: elixir-guidelines
description: Apply Elixir community style conventions, BEAM/OTP engineering guidelines, and this repository's Phoenix project rules when writing, reviewing, or refactoring code. Cover all 25 official Elixir v1.20.5 anti-patterns and verify changes with Mix and ExUnit. Trigger for .ex/.exs code, Elixir style reviews, Phoenix/Ecto/HEEx/LiveView work, Phoenix frontend assets and UI, GenServer/Supervisor design, macro authoring, and Elixir maintainability or performance work.
metadata:
  source: "Elixir 1.20.5 official anti-pattern guides; community Elixir Style Guide; repository AGENTS.md"
  version: "1.3.0"
---

# Elixir Guidelines

Use this skill for new Elixir code, modifications to existing Elixir applications, architecture reviews, and focused audits of Elixir code. Engineering guidance is grounded in the **25 official potential anti-patterns documented for Elixir v1.20.5**. Style guidance comes from the community **Elixir Style Guide**; keep community preferences distinct from the official anti-pattern catalog.

## Core principles

1. **Avoid dogmatic rewrites.** A pattern may be reasonable for a particular workload. Explain the concrete failure mode, evidence, and trade-off before suggesting a change.
2. **Prefer explicit, idiomatic code.** Favor pattern matching, appropriately strict map access, clear return contracts, small functions, and domain-shaped data.
3. **Separate behavior from concurrency.** Use functions and modules for code organization; add processes to meet runtime requirements (state ownership, isolation, concurrency, lifecycle).
4. **Respect the BEAM.** Consider copying across process boundaries, queueing and bottlenecks, supervision, atom allocation, and compile-time dependency graphs.
5. **Prefer functions over macros** unless compile-time code generation or AST access is necessary. Keep generated code small and dependencies tracked.
6. **Keep changes minimal and testable.** Do not modify public APIs, error semantics, supervision strategies, or timing without assessing callers and tests.

## Workflow

1. **Identify scope and project requirements.** Review affected `.ex`, `.exs`, `mix.exs`, tests, and relevant call sites. Determine whether this is application code, a reusable library, or a one-off script. Confirm the project's Elixir/OTP versions before applying version-specific advice. For this repository, load the applicable project references below before making changes; their requirements take precedence over community style preferences. When using this skill elsewhere, follow that repository's instructions.
2. **Load the matching reference.** When writing or reviewing source style, read [references/style.md](references/style.md) for formatting, expressions, naming, module organization, documentation, typespecs, data syntax, and assertions. Read `references/code.md` for ordinary Elixir source; `references/design.md` for API/domain/module design; `references/process.md` for OTP, Task, Agent, and message-passing code; `references/metaprogramming.md` for `quote`, `defmacro`, `use`, compile-time evaluation or dependency issues. For a full audit, read all five. Apply explicit user/project rules and configured formatter/linter behavior before community style preferences; preserve semantics and version compatibility.
3. **Find candidates, not just syntax matches.** Examine the surrounding invariants, data input trust boundary, process lifecycle, contracts, caller expectations, workload and benchmarks. A matching syntax alone is not proof of an issue.
4. **Prioritize by risk.** Address crash/security/correctness hazards first, then supervision and concurrency issues, unexpected return contracts and compile correctness, and only then readability and premature optimization. Don't assert a performance improvement without profiling or benchmarking.
5. **Choose a proportionate fix.** Prefer the smallest change that resolves the demonstrated problem. If the existing approach is justified, keep it and explain why. Preserve behavior unless the user explicitly requests an intentional semantic change.
6. **Add regression coverage where behavior changes.** Cover malformed inputs, missing keys, error tuples, process failure/restart, public API contracts, or macro recompilation dependencies where relevant. For documentation-only changes, validate links and affected examples rather than adding application tests that assert document wording.
7. **Verify proportionately.** Follow the project's completion checks in `references/project.md`. For code changes, run the configured formatter, compilation, and relevant tests, or the project alias that already includes them. Use optional Credo, Dialyzer, and `mix xref` checks where they address the change. `scripts/check.sh` is an alternative baseline, not an additional mandatory repeat of successful checks. State which commands actually ran, and distinguish introduced failures from existing/environment failures.

## Project requirements moved from AGENTS.md

| When working in this repository | Read and apply |
| --- | --- |
| Any change, including completion checks; Elixir, HTTP clients, Mix, or tests | [references/project.md](references/project.md) |
| Phoenix routing, layouts, HEEx, LiveView, forms, streams, hooks, or LiveView tests | [references/phoenix.md](references/phoenix.md) |
| Phoenix frontend assets, Tailwind/CSS/JavaScript, or UI design | [references/frontend.md](references/frontend.md) |

These references adapt the former root `AGENTS.md` guidelines, correct their examples, and link
official API contracts separately from local policy. Load all three for a full project audit;
for a focused change, load only the applicable references.

## Reporting format

For each substantial finding provide:

- **Severity**: critical / high / medium / low, based on likely impact in this repository (not an intrinsic severity of the pattern).
- **Pattern or style rule**: exact catalog name and category for official anti-patterns, or the community style rule labeled as a style preference.
- **Location**: file and line(s), or a clear code reference.
- **Evidence and impact**: the observed problematic behavior and why it matters here.
- **Suggested change**: minimal practical refactoring and any effect on the existing contract.
- **Validation**: test, profiler, runtime check, or experiment to verify the conclusion.

Report only substantiated findings. Distinguish confirmed bugs from risks and stylistic suggestions. If there are no actionable findings, explicitly say so. For implementations, apply the guidance silently unless the user requests an audit.

## Complete catalog (25)

### Code-related (10)

1. Comments overuse
2. Complex `else` clauses in `with`
3. Complex extractions in clauses
4. Dynamic atom creation
5. Long parameter list
6. Namespace trespassing
7. Non-assertive map access
8. Non-assertive pattern matching
9. Non-assertive truthiness
10. Structs with 32 fields or more

Read **`references/code.md`** for recognition, fixes, exceptions and examples.

### Design-related (6)

11. Alternative return types
12. Boolean obsession
13. Exceptions for control-flow
14. Primitive obsession
15. Unrelated multi-clause function
16. Using application configuration for libraries

Read **`references/design.md`**.

### Process-related (4)

17. Code organization by process
18. Scattered process interfaces
19. Sending unnecessary data
20. Unsupervised processes

Read **`references/process.md`**.

### Meta-programming (5)

21. Compile-time dependencies
22. Large code generation
23. Unnecessary macros
24. `use` instead of `import`
25. Untracked compile-time dependencies

Read **`references/metaprogramming.md`**.

## Illustrative example

Instead of silently tolerating absent required keys:

```elixir
# Problem: a missing required :user_id becomes nil and fails much later.
def enqueue_job(attrs), do: WorkQueue.enqueue(attrs[:user_id])

# Better when :user_id must exist.
def enqueue_job(attrs), do: WorkQueue.enqueue(attrs.user_id)

# Or explicitly match a domain invariant.
def enqueue_job(%{user_id: user_id}), do: WorkQueue.enqueue(user_id)
```

This advice applies only when `:user_id` is truly required; `attrs[:optional_key]` remains appropriate for optional keys.

## References and provenance

The authoritative primary source is the official [What are anti-patterns?](https://elixir.hexdocs.pm/1.20.5/what-anti-patterns.html) guide, with its [code](https://elixir.hexdocs.pm/1.20.5/code-anti-patterns.html), [design](https://elixir.hexdocs.pm/1.20.5/design-anti-patterns.html), [process](https://elixir.hexdocs.pm/1.20.5/process-anti-patterns.html), and [meta-programming](https://elixir.hexdocs.pm/1.20.5/macro-anti-patterns.html) chapters. The reference files here are original, condensed operational guidance, **not a verbatim mirror**. Elixir's official guide explicitly cautions that matches are potential smells, not mandatory rewrites.

[references/style.md](references/style.md) adapts the user-supplied [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) by Christopher Adams and contributors, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). It condenses the guide, omits community administration material, and makes compatibility and project-tooling exceptions explicit.
