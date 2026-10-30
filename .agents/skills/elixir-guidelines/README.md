# elixir-guidelines

Portable Agent Skill combining **all 25 official Elixir v1.20.5 anti-patterns** with the
community **Elixir Style Guide**, plus this repository's guidelines moved from `AGENTS.md`.
Project instructions and configured formatters take precedence over community style preferences.

## Contents

- `SKILL.md`: activation metadata, working instructions, audit/output format, complete index.
- `references/style.md`: community formatting, expressions, naming, modules, docs, typespecs, data syntax, and testing conventions.
- `references/project.md`: project Elixir, HTTP client, Mix, test process, and completion-check requirements.
- `references/phoenix.md`: project Phoenix 1.8, HEEx, LiveView, form, stream, hook, and UI-test requirements.
- `references/frontend.md`: project Tailwind, CSS/JavaScript bundle, and UI design requirements.
- `references/code.md`: 10 code-related anti-patterns.
- `references/design.md`: 6 design-related anti-patterns.
- `references/process.md`: 4 OTP/process anti-patterns.
- `references/metaprogramming.md`: 5 macro/compiler anti-patterns.
- `scripts/check.sh`: safe read-only project quality checks; no dependency installation.

## Install in your code repository

Copy the whole `elixir-guidelines` folder to `.agents/skills/elixir-guidelines/` for agents that discover `.agents/skills`. For tools that use a client-specific skill directory, copy it to that client's documented `skills/` location instead. The parent directory and discovery mechanism depend on the agent; the skill's internal format follows the Agent Skills specification: https://agentskills.io/specification.

The three project references preserve this repository's local requirements. In another repository,
follow its own project instructions rather than automatically imposing these local requirements.

Example usage: "Use the `elixir-guidelines` skill to review `lib/` for correctness and BEAM/OTP anti-patterns. Report file/line, severity, evidence, and refactoring suggestions."

Quick checks: `bash .agents/skills/elixir-guidelines/scripts/check.sh` from a Mix project directory (requires Elixir/Mix; checks optional tools only if they exist).

Original source: https://elixir.hexdocs.pm/1.20.5/what-anti-patterns.html. This work contains paraphrased recommendations and independent examples, not a reproduction of the documentation.

Style source: [The Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
by Christopher Adams and contributors, adapted from the user-supplied text under
[CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). The adaptation condenses the guide and
adds project-tooling and compatibility notes; see `references/style.md` for attribution.
