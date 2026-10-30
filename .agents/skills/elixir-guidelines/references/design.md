# Design-related anti-patterns (6)

Source: [Elixir v1.20.5 — Design-related anti-patterns](https://elixir.hexdocs.pm/1.20.5/design-anti-patterns.html). These are contextual design smells, not mandatory refactoring triggers.

## 11. Alternative return types

**Detect:** A runtime option changes a function's *shape* of return value (a scalar vs a tuple vs a struct) instead of only its behavior.

**Risk:** Callers cannot confidently pattern-match or specify the return type without tracking hidden options.

**Prefer:** Give each substantially different return contract a separate, descriptive function; write accurate `@spec`s.

```elixir
# Problem: return type depends on discard_rest: option.
parse(text, discard_rest: true)   # 12
parse(text, discard_rest: false)  # {12, "xyz"}

# Prefer separate names/contracts.
def parse(text), do: Integer.parse(text)
def parse_integer_only(text) do
  case Integer.parse(text) do
    {value, _rest} -> {:ok, value}
    :error -> :error
  end
end
```

**Do not flag:** Options that change content but keep the same documented return contract; established interfaces where changing them would be a breaking API change without sufficient justification.

## 12. Boolean obsession

**Detect:** Multiple overlapping boolean options or fields encode an exclusive state (e.g., `admin?` + `editor?` + `viewer?`).

**Risk:** Invalid combinations and implicit precedence rules; adding a state becomes error prone.

**Prefer:** A single enumerated atom (`role: :admin | :editor | :viewer`) or a well-defined tagged tuple/struct. Keep genuine independent flags as booleans.

```elixir
# Ambiguous overlapping permissions.
%{admin?: true, editor?: true}

# Exclusive role is easier to validate.
%{role: :admin}
```

**Do not flag:** Independently meaningful flags that are orthogonal; multiple booleans are not inherently wrong.

## 13. Exceptions for control-flow

**Detect:** `try/rescue` around expected operational failures (e.g. missing file, validation error), when non-raising APIs exist.

**Risk:** Normal outcomes are hidden among exceptional ones, and callers cannot decide how to handle an expected failure.

**Prefer:** Pattern-match `{:ok, result}` / `{:error, reason}` from non-bang functions; reserve raised exceptions for exceptional failures, programmer errors and deliberate crash semantics.

```elixir
# Avoid: rescue expected no-file errors as regular flow.
try do
  {:ok, File.read!(path)}
rescue
  File.Error -> {:error, :unavailable}
end

# Prefer:
case File.read(path) do
  {:ok, bytes} -> {:ok, bytes}
  {:error, reason} -> {:error, reason}
end
```

**Do not flag:** `!` functions in setup, tests, scripts, or places where an invariant failure should crash; Phoenix frameworks may deliberately map exceptions to HTTP responses. Do not blanket-rescue failures that need observation.

## 14. Primitive obsession

**Detect:** Several functions repeatedly parse and manipulate a domain concept encoded as a plain string, float, or integer (addresses, money, identifiers, units).

**Risk:** Validation rules are duplicated, invariants are easy to violate, and calling code becomes opaque.

**Prefer:** Introduce dedicated domain structures and parsing/validation boundaries, then operate on validated domain values. Avoid floats for money; use integer minor units or appropriate decimal/money types.

```elixir
defmodule Price do
  @enforce_keys [:amount_minor, :currency]
  defstruct [:amount_minor, :currency]
end

# Consistent structure is preferable to passing "19.99 USD" everywhere.
```

**Do not flag:** Simple primitives that genuinely capture the domain, especially when introducing a struct adds unjustified coupling or a costly compile dependency.

## 15. Unrelated multi-clause function

**Detect:** One function name dispatches between fundamentally different business operations only because arguments happen to have different struct types.

**Risk:** Imprecise contracts, surprising APIs, poor naming and unrelated changes coupling one function together.

**Prefer:** Split into separately named functions/modules when effects and semantics differ. Keep multi-clause functions where all clauses represent the *same operation*.

```elixir
# Suspicious if operations mean unrelated business actions.
def update(%Invoice{} = invoice), do: ...
def update(%Animal{} = animal), do: ...

# Better when semantics really differ.
def update_invoice(%Invoice{} = invoice), do: ...
def update_animal(%Animal{} = animal), do: ...
```

**Do not flag:** Consistent polymorphic operations such as conversions or shared protocol-based behavior.

## 16. Using application configuration for libraries

**Detect:** A reusable library reads `Application.get_env/3` directly to decide per-call behavior that callers may need to vary.

**Risk:** The global application environment couples independent consumers to one configuration value and makes libraries harder to reuse or test.

**Prefer:** Accept options at the function/constructor boundary, expose a child spec configurable by the owning application, use behaviours for interchangeable components, or let the application read config and inject it.

```elixir
# Avoid global per-call configuration inside a reusable library.
def split(text), do: String.split(text, "-", parts: Application.fetch_env!(:lib, :parts))

# Prefer caller-controlled behavior.
def split(text, opts \\ []) do
  String.split(text, "-", parts: Keyword.get(opts, :parts, 2))
end
```

**Do not flag:** Application-owned configuration in an application's own code; configuration for a truly shared implementation or startup resource; unavoidable compile-time library configuration; Mix-task-specific configuration. Review the official guide's nuanced discussion of supervision trees, compile-time values, `:otp_app` and Mix tasks before changing those patterns.

## Review priorities

Focus on clear contracts, expected failure semantics, domain invariants and library composability. Before replacing a published API, identify downstream callers and compatibility requirements.
