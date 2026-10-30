# Code-related anti-patterns (10)

Source: [Elixir v1.20.5 — Code-related anti-patterns](https://elixir.hexdocs.pm/1.20.5/code-anti-patterns.html). These notes paraphrase the official guide for actionable review and implementation. Use context; none of these patterns is an unconditional prohibition.

## 1. Comments overuse

**Detect:** Line-by-line comments narrate ordinary assignments, calls or loops; comments repeat readable function names; outdated comments diverge from the code.

**Risk:** Adds noise, maintenance burden and sometimes misinformation.

**Prefer:** Express intent via clear names, small functions and meaningful module attributes. Use `@doc`/`@moduledoc` for API/module contracts, and comments for *why*, non-obvious constraints, security trade-offs or external quirks.

```elixir
# Weak: comment merely narrates the expression.
# Add five minutes to the current Unix timestamp.
def expiry, do: DateTime.utc_now() |> DateTime.add(5, :minute) |> DateTime.to_unix()

# Better: code is already self-explanatory.
def expiry, do: DateTime.utc_now() |> DateTime.add(5, :minute) |> DateTime.to_unix()
```

**Do not flag:** Comments that document an invariant, unusual reason, performance measurement, external contract, or operational hazard.

## 2. Complex `else` clauses in `with`

**Detect:** Many unrelated `<-` matches in a `with`; a dense `else` must infer which operation failed, or different operations return indistinguishable error shapes.

**Risk:** Ambiguous error ownership, weak traceability, brittle changes.

**Prefer:** Normalize error variants at the operation boundary (private wrappers), then make the `with` read as a success pipeline.

```elixir
def load_encoded(path) do
  with {:ok, bytes} <- read_file(path),
       {:ok, decoded} <- decode(bytes) do
    {:ok, decoded}
  end
end

defp read_file(path) do
  case File.read(path) do
    {:ok, bytes} -> {:ok, bytes}
    {:error, _} -> {:error, :file_unavailable}
  end
end

defp decode(bytes) do
  case Base.decode64(bytes) do
    {:ok, value} -> {:ok, value}
    :error -> {:error, :invalid_encoding}
  end
end
```

**Do not flag:** A short, readable `else` with unambiguous branches, or intentional propagation of existing error tuples.

## 3. Complex extractions in clauses

**Detect:** Multiple clauses bind many map/struct fields in function heads; most bindings are used only in bodies, making guards/dispatch hard to distinguish.

**Risk:** Readers cannot tell which fields determine clause selection; changes complicate signatures.

**Prefer:** Keep head matches to invariants and fields needed for guards or dispatch. Bind the whole struct and extract body-only fields inside.

```elixir
# Too much extraction in the head when repeated throughout a large multi-clause function.
def access(%User{name: name, role: :admin, email: email}), do: {name, email}

# Use dispatch-focused head matching.
def access(%User{role: :admin} = user), do: {user.name, user.email}
```

**Do not flag:** Small multi-clause functions where head destructuring clearly improves readability.

## 4. Dynamic atom creation

**Detect:** `String.to_atom/1` or `binary_to_atom` invoked on unbounded external request, message, file or database values.

**Risk:** Atoms are not garbage collected; unbounded creation may exhaust the atom table and take down the VM.

**Prefer:** Keep untrusted values as strings, use an explicit bounded lookup, or carefully use `String.to_existing_atom/1` when semantics permit (it **does not** validate membership in an allowed set).

```elixir
@status_by_string %{"pending" => :pending, "active" => :active}

def parse_status(value) when is_binary(value) do
  case Map.fetch(@status_by_string, value) do
    {:ok, status} -> {:ok, status}
    :error -> {:error, :unknown_status}
  end
end
```

**Do not flag:** Compile-time or strictly finite, controlled atom generation. Confirm that converting to existing atoms still enforces the actual allowlist when authorization or validation matters.

## 5. Long parameter list

**Detect:** High-arity functions take related primitive fields whose order is easy to mix up.

**Risk:** Poor discoverability and error-prone calling; often reveals misplaced responsibilities.

**Prefer:** Group cohesive arguments in domain maps/structs; reserve keyword options for truly optional configuration; split unrelated responsibilities rather than hiding everything in one giant options map.

```elixir
# Weak: similar-looking string arguments can be swapped.
def issue_invoice(customer_id, street, city, postcode, currency, total), do: ...

# Better: domain-shaped arguments.
def issue_invoice(%Customer{} = customer, %Address{} = address, %Money{} = total), do: ...
```

**Do not flag:** An arity threshold mechanically. A function with a few semantically independent parameters can be clearer than an artificial map.

## 6. Namespace trespassing

**Detect:** A reusable library defines modules inside another dependency's namespace.

**Risk:** Module name collisions when libraries coexist or upstream gains a new module.

**Prefer:** Prefix exported modules with the package's namespace (e.g., `MyPlugin.Auth`, not `Plug.Auth` for an unrelated library).

**Do not flag:** `Mix.Tasks.*` tasks, protocol implementations, and other documented extension points explicitly owned/allowed by the namespace maintainer.

## 7. Non-assertive map access

**Detect:** `map[:required_key]` when the key is contractual and missing values are errors.

**Risk:** Unexpected `nil` silently flows into later code, producing errors distant from the cause.

**Prefer:** `map.required_key`, `Map.fetch!/2`, or an explicit map/struct pattern for required values; `map[:optional_key]` for optional fields and dynamic Access-based lookup.

```elixir
# User ID is a required contract field.
def user_id(attrs), do: attrs.user_id
# An alternative, especially when matching several required keys:
# def user_id(%{user_id: id}), do: id

# Description is genuinely optional.
def description(attrs), do: attrs[:description]
```

**Do not flag:** Optional or dynamically chosen keys, Access-based APIs, or a map where `nil` is the intended missing-value result.

## 8. Non-assertive pattern matching

**Detect:** Catch-all `_` branches swallow unexpected return shapes; indexing into structures replaces clear shape checks; defensive defaults turn malformed data into plausible values.

**Risk:** Contract changes and invalid inputs are hidden rather than producing meaningful errors.

**Prefer:** Match known cases and use guards; reject bad data at boundaries with explicit `{:error, reason}` where invalid input is expected. Let true programmer invariant violations fail clearly.

```elixir
case fetch_user(id) do
  {:ok, user} -> {:ok, user}
  {:error, :not_found} -> {:error, :not_found}
end
```

**Do not flag:** An intentional catch-all that is required by the protocol, external input handling, or a genuinely open-ended variant; make its behavior explicit and test it. Avoid introducing crashes for malformed external input that the app should reject gracefully.

## 9. Non-assertive truthiness

**Detect:** `&&`, `||` or `!` when the contract requires booleans, particularly around Erlang APIs returning truthy atoms such as `:undefined`.

**Risk:** Looser semantics can treat unexpected non-boolean values as truthy.

**Prefer:** `and`, `or`, `not` where boolean semantics are truly required; use `&&`/`||` when deliberately returning operands or short-circuiting optional values.

```elixir
# Boolean predicates => explicit boolean operators.
if is_binary(name) and is_integer(age), do: :valid, else: :invalid

# Value selection: || can be appropriate, but consider whether false is meaningful.
label = provided_label || "Untitled"
```

**Do not flag:** Intentional truthiness, nil-coalescing behavior, or a non-boolean value as part of a documented API.

## 10. Structs with 32 fields or more

**Detect:** A frequently allocated or updated struct declares 32 or more custom fields.

**Risk:** The BEAM's map representation changes after the flat-map threshold. Every struct also stores a `__struct__` key, so **32 declared fields** place the struct beyond a 32-key flat map. Extra memory/compilation costs may matter in hot paths.

**Prefer:** If justified by profiling and domain design, group related or rarely-used fields into nested structs/maps, or reduce the model's responsibilities. Benchmark on target OTP versions.

**Do not flag:** Data transfer models that are naturally wide, Ecto schemas whose fields reflect actual persisted data, or rarely instantiated structs without measured impact. Do **not** compromise a sound domain model solely to meet a number.

## Review priorities

- **Highest concern:** unbounded atom creation from untrusted data, critical missing-field invariants.
- **Medium/contextual:** confusing `with` error paths, over-defensive pattern matching, ambiguous truthiness.
- **Maintainability/performance candidates:** comments, extraction style, long arguments, namespaces, wide structs.

When reporting a finding, include the observed input or runtime behavior and a test that would catch the failure.
