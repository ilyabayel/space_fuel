# Community Elixir style

Adapted from the user-supplied [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
by Christopher Adams and contributors, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
The upstream guide credits the [Ruby community style guide](https://github.com/bbatsov/ruby-style-guide)
for its structure, some examples, and initial recommendations. This adaptation condenses the rules,
uses independent examples, and adds the precedence and compatibility notes below.

These are community style preferences. Apply explicit user/project instructions and the project's
configured formatter and linter first. Preserve behavior, public contracts, and compatibility with
the project's Elixir version. Limit style changes to the requested scope.

## Contents

- [Formatting](#formatting)
- [Expressions](#expressions)
- [Naming](#naming)
- [Comments and annotations](#comments-and-annotations)
- [Modules](#modules)
- [Documentation and typespecs](#documentation-and-typespecs)
- [Structs, collections, and strings](#structs-collections-and-strings)
- [Exceptions, macros, and tests](#exceptions-macros-and-tests)

## Formatting

Use `mix format` with the existing `.formatter.exs` and plugins. Let the formatter own mechanical
layout; treat the following as defaults where tooling leaves a choice. The upstream defaults are
98 characters for source lines and 100 for comments; honor a configured `:line_length` instead.

- Use spaces, Unix line endings, no trailing whitespace, and a final newline. Keep line-ending
  settings local to the task; adding this guide does not call for global Git configuration changes.
- Put spaces around binary operators and after commas, colons, and semicolons; keep matched
  delimiters tight. Keep unary operators next to their operand and ranges tight: `-n`, `^id`, `1..8`.
- Separate functions and logical paragraphs with blank lines. Keep adjacent one-line clauses of
  the same function together; separate multiline clauses. Put no blank line after `defmodule`.
- A long function head may continue with `do:` on the next line, indented one level; separate that
  definition from its neighbors as a multiline definition. Add a blank line after multiline assignments.
- For multiline list/map/struct literals, put delimiters and elements on separate lines, indent the
  elements one level, and keep the opening delimiter on the assignment line.
- If one `case` or `cond` clause requires a multiline body, use multiline bodies for every clause
  and separate clauses with blank lines.
- Align successive `with` clauses. A one-line result may use a final aligned `do:` line; use
  `do ... end` when the body is multiline or an `else` is present.
- Use parentheses for function calls, including zero-arity calls and pipeline stages, with no space
  before `(`. Respect configured DSL/macros that omit parentheses, such as `defstruct`.
- Omit brackets around a final keyword-list argument when optional: `fetch(key, timeout: 500)`.

## Expressions

- Group clauses of one function. If multiple clauses have multiline bodies, prefer block syntax
  consistently for that function; otherwise adjacent short `do:` clauses are appropriate.
- Use pipelines for a sequence of transformations, starting from a bare input when practical.
  Prefer a direct call for a single transformation. Keep each multiline `|>` aligned with the input;
  place an assigned multiline pipeline on a new indented line.
- Define functions with parentheses when they take arguments. The supplied guide omits them in
  zero-arity definitions (`def ready, do: :ok`), while calls use `ready()`. Follow project formatter
  behavior if it chooses `def ready()` instead.
- Use `do:` for a single-line conditional. Express two-way branches as `if ... else` with the positive
  condition first. On versions supporting `unless`, reserve it for a negative branch without `else`;
  use `if` where `unless` is deprecated or unavailable.
- Use `true` for an intentional catch-all branch of `cond`.

```elixir
def normalize_label(label) do
  label
  |> String.trim()
  |> String.downcase()
end

def label_length(label), do: String.length(label)
```

## Naming

- Use `snake_case` for atoms, variables, and functions; use `CamelCase` for modules and preserve
  acronyms such as `HTTP`, `RFC`, and `XML`.
- Give boolean-returning functions a trailing `?`; reserve `is_` for guard-compatible checks.
  Naming an ordinary function `is_...` does not make it callable in guards; use `defguard` when needed.
- Choose private helper names that describe their distinct work, rather than sharing a public
  function's name at another arity or mechanically prefixing it with `do_`.
- Prefer meaningful namespaces without repeated fragments, such as `Inventory.Item`.

## Comments and annotations

- Express intent through names and structure; explain rationale or constraints in comments.
  See [code.md](code.md#1-comments-overuse) for the official comments-overuse anti-pattern.
- Put comments above the relevant code, with one space after `#`. Capitalize multiword comments,
  punctuate complete sentences, and use one space after periods.
- Write annotations above their target as `KEYWORD: explanation`. A bare keyword is appropriate
  only when the problem is self-evident. Document custom annotation keywords in project documentation.

| Keyword | Meaning |
| --- | --- |
| `TODO` | Missing functionality to add later |
| `FIXME` | Broken behavior to repair |
| `OPTIMIZE` | Inefficiency that may affect performance |
| `HACK` | A questionable workaround to revisit |
| `REVIEW` | Behavior or an assumption requiring confirmation |

## Modules

- Prefer one module per file. The upstream guide allows internal helper/test modules together;
  apply stricter project rules where present.
- Use `snake_case` filenames and directories for namespace levels:
  `Warehouse.Stock.Entry` maps to `warehouse/stock/entry.ex` beneath the source root.
- Order module contents as below, separating groups with blank lines and alphabetizing comparable
  directives within a group when evaluation order permits. Preserve dependency-sensitive ordering.

  1. `@moduledoc`
  2. `@behaviour`
  3. `use`
  4. `import`
  5. `require`
  6. `alias`
  7. Other module attributes
  8. `defstruct`
  9. Types (`@typedoc` with `@type`)
  10. `@callback`
  11. `@macrocallback`
  12. `@optional_callbacks`
  13. Function, macro, and guard definitions

- Use `__MODULE__` for self-references. An explicit alias such as
  `alias __MODULE__, as: Entry` is appropriate when it improves readability.

## Documentation and typespecs

- Place `@moduledoc` immediately after `defmodule`, then a blank line before code. Use
  `@moduledoc false` for intentionally undocumented modules.
- Use Markdown heredocs for documentation, with headings such as `## Examples` and indented IEx
  examples. Write examples as function calls with parentheses.
- Keep each `@typedoc` adjacent to its `@type`, separating type/documentation pairs with blank lines.
- Name a module's principal type `t`, especially for a struct: `@type t :: %__MODULE__{...}`.
- Put each alternative of a long union type on its own continuation line with aligned `|` operators.
- Keep a function's `@doc`, `@spec`, and definition adjacent, in that order.

## Structs, collections, and strings

- List fields defaulting to `nil` as atoms before explicit keyword defaults:
  `defstruct [:reference, :label, enabled: true]`.
- For a keyword-only `defstruct`, omit optional brackets: `defstruct enabled: true`.
  Keep brackets when atoms are present. In multiline definitions, put one field per line and align
  keyword entries; bracketed definitions follow multiline-list layout.
- Use keyword syntax for keyword lists: `[timeout: 500, retries: 2]`.
- Use shorthand map keys when all are atoms: `%{status: :ready, count: 2}`. The supplied guide prefers
  `=>` for every entry if any key is not an atom: `%{:status => :ready, "count" => 2}`.
- Match a literal string prefix with concatenation when sufficient:
  `"event:" <> payload = message`. Use binary patterns when bit/byte-level structure is relevant.

## Exceptions, macros, and tests

- End exception module names with `Error`. Prefer lowercase exception messages without trailing
  punctuation; preserve externally relied-on messages unless changing them is in scope.
- Prefer ordinary functions when compile-time code generation or AST manipulation is unnecessary;
  use [metaprogramming.md](metaprogramming.md) for macro engineering guidance.
- Put the actual expression on the left and expected value on the right in equality assertions:
  `assert total(items) == 42`. Pattern-match assertions put the expected pattern on the left:
  `assert {:ok, result} = calculate(items)`. Preserve the assertion's semantics.
