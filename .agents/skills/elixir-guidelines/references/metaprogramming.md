# Meta-programming anti-patterns (5)

Source: [Elixir v1.20.5 — Meta-programming anti-patterns](https://elixir.hexdocs.pm/1.20.5/macro-anti-patterns.html). Review macro expansion, generated AST and dependency tracking against the compiler behavior of the project's Elixir version.

## 21. Compile-time dependencies

**Detect:** A macro resolves a module reference eagerly at module level even though the referenced module will only be called at runtime. One change triggers widespread transitive recompilation.

**Risk:** Unnecessarily broad compile-time dependency graphs, slow incremental builds, extra recompilation.

**Prefer:** Where a module reference is only required inside a generated function, avoid forcing it into a module-body compile-time dependency. In suitable macros, use `Macro.expand_literals/2` with the correct caller environment representing the function, **only when the macro does not inspect or invoke that module at compile time**.

```elixir
# Excerpt adapted conceptually from the compiler guidance:
defmacro route(mod) do
  mod = Macro.expand_literals(mod, %{__CALLER__ | function: {:call, 2}})

  quote do
    @routes unquote(mod)
  end
end
```

**Validate:** Use `mix xref trace path/to/file.ex` and monitor how many files get recompiled after editing dependencies. Inspect macro expansion when necessary.

**Do not flag:** A legitimate compile-time dependency, such as struct shape validation or functions that must run during compilation. Never mechanically apply the `Macro.expand_literals` technique to a macro with compile-time module interactions.

## 22. Large code generation

**Detect:** A frequently-invoked macro duplicates lengthy validation, data processing or runtime logic into every caller module.

**Risk:** Slower compilation, larger BEAM artifacts and harder debugging.

**Prefer:** Keep the expanded AST minimal; move shared work into ordinary helper functions. A thin macro may pass the caller's module, AST, or validated literals to a helper run at the appropriate phase.

```elixir
defmacro register(key, value) do
  quote do
    Registration.__register__(__MODULE__, unquote(key), unquote(value))
  end
end

# Registration.__register__/3 holds substantial shared logic.
```

**Do not flag:** Small, necessary generated branches whose expansion is justified by measured runtime or compile-time trade-offs. Ensure helper availability and phase semantics remain correct after extraction.

## 23. Unnecessary macros

**Detect:** A `defmacro` does no more than pass evaluated arguments to ordinary calculations or function calls, without requiring caller AST or compile-time specialization.

**Risk:** More complicated semantics, evaluation-order surprises, compile-time coupling and difficult tests.

**Prefer:** Plain functions. Use macros when the caller AST, syntax extension or unavoidable compile-time code generation is essential.

```elixir
# Unnecessary macro:
defmacro add(a, b) do
  quote do: unquote(a) + unquote(b)
end

# Function is clearer:
def add(a, b), do: a + b
```

**Do not flag:** Macros required to establish behaviours, define a DSL, provide guard-compatible syntax, or generate compile-time code where functions cannot substitute.

## 24. `use` instead of `import`

**Detect:** A library offers `__using__/1` solely to import or alias helper modules, often with surprising transitive imports or injected state.

**Risk:** Hidden imports, collisions, compilation dependencies and code whose meaning relies on undocumented injected definitions.

**Prefer:** `import` or `alias` when those are all that is needed; reserve `use` for genuine extension points that define callbacks, injected functions, child specs or other compile-time behavior.

```elixir
# Not worth a custom __using__/1 when it merely imports helpers:
import MyLib.Helpers

# 'use MyLib' is justified only if it intentionally injects additional behavior.
```

**Document:** For genuine `use` macros, explain the public effects of `use MyLib` in `@moduledoc` (the guide calls this a "nutrition facts" explanation).

**Do not flag:** Standard `use GenServer`, `use Phoenix.*`, `use Ecto.*` and other genuine behaviour/DSL integration without identifying a concrete problem.

## 25. Untracked compile-time dependencies

**Detect:** Code running at compile time constructs module aliases dynamically via `Module.concat/2`, raw `:"Elixir..."` atoms, or other mechanisms that prevent the compiler from seeing referenced aliases.

**Risk:** Changed dependencies may not trigger the recompilation of dependent modules, causing stale generated code or compilation inconsistencies.

**Prefer:** Use explicit module aliases in compile-time lists, or generate actual alias AST in a macro so the compiler can track dependencies.

```elixir
# Problem in compile-time module bodies:
for part <- [:Foo, :Bar] do
  Module.concat(MyApp, part).build()
end

# Better: explicit aliases are tracked by the compiler:
for mod <- [MyApp.Foo, MyApp.Bar] do
  mod.build()
end
```

**Validate:** Use `mix xref trace path/to/file.ex` and a targeted incremental recompilation test. A dynamic module reference *at runtime* is not automatically this anti-pattern.

**Do not flag:** Runtime dynamic dispatch or deliberate code generation that explicitly establishes proper compile-time dependencies.

## Macro review checklist

1. Do we need a macro at all? Can a function do the job?
2. What code does expansion duplicate, and how often?
3. Does `use` inject functions/imports/attributes, and is that documented?
4. Are module aliases expanded in the correct compilation phase?
5. Is every genuine compile-time dependency visible to the compiler?
6. Does `mix xref trace` match the expected dependency type?
7. Are macro expansion tests and recompilation tests available?
