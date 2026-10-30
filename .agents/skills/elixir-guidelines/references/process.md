# Process-related anti-patterns (4)

Source: [Elixir v1.20.5 — Process-related anti-patterns](https://elixir.hexdocs.pm/1.20.5/process-anti-patterns.html). Processes are appropriate for runtime concerns; do not equate "using a GenServer" with a defect.

## 17. Code organization by process

**Detect:** A `GenServer`/`Agent` mediates stateless computations, merely to group related functions or provide a namespace. Every call unnecessarily crosses a serialized mailbox.

**Risk:** Single-process contention, timeouts, needless scheduling/message-passing overhead and complexity.

**Prefer:** Plain functions and modules for stateless calculations; use processes for *runtime* requirements such as mutable state ownership, resource management, concurrency coordination, fault isolation, and asynchronous work.

```elixir
# Unnecessary process for stateless calculations:
# GenServer.call(Calculator, {:add, x, y})

# Better:
defmodule Calculator do
  def add(x, y), do: x + y
end
```

**Do not flag:** State-holding `GenServer`s managing a connection or resource, or a process required for sequencing, failure isolation, bounded concurrency or backpressure. Review mailbox growth and scheduler behavior before recommending architectural changes.

## 18. Scattered process interfaces

**Detect:** Arbitrary application modules directly call `Agent.update`, `GenServer.call/cast` on the same process and know its private message protocol or state shape.

**Risk:** Protocol changes ripple across the codebase, validations are skipped, and process state may become inconsistent.

**Prefer:** Public client functions on the module that owns the process; encapsulate message formats, state transitions and validation in one place.

```elixir
defmodule Counter do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, 0, opts)
  def increment(server, amount), do: GenServer.call(server, {:increment, amount})

  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_call({:increment, amount}, _from, count) when is_integer(amount) do
    new_count = count + amount
    {:reply, {:ok, new_count}, new_count}
  end
end

# Consumers call Counter.increment(pid, 3), not GenServer.call(pid, {:increment, 3}).
```

**Do not flag:** Deliberate generic process interfaces or well-defined OTP protocol calls (`GenServer` as infrastructure) when encapsulation provides no benefit.

## 19. Sending unnecessary data

**Detect:** A task closure captures a large `Plug.Conn`, payload, struct, or in-memory collection but uses only one field; messages send entire structs rather than needed values.

**Risk:** Ordinary terms are copied into the destination process heap; high volume or large messages can cause CPU/memory pressure. Large binaries can have different reference-counted semantics, so distinguish them from arbitrary terms.

**Prefer:** Extract the smallest data before `Task.async`, `Task.start`, `spawn`, `send`, `GenServer.call/cast`. If useful, let the receiver fetch data from a controlled source. Measure actual memory and throughput.

```elixir
# Even though the closure only reads one field, it captures conn:
Task.start(fn -> record_ip(conn.remote_ip) end)

# Extract before spawning so the closure captures only the address:
ip = conn.remote_ip
Task.start(fn -> record_ip(ip) end)

# Likewise, avoid sending the whole conn:
GenServer.cast(server, {:record_ip, conn.remote_ip})
```

**Do not flag:** Small terms, stable API payloads needed in full, or intentionally shared immutable large binaries; verify actual BEAM copy behavior before claiming a measured cost.

## 20. Unsupervised processes

**Detect:** Important long-running processes are spawned or started outside a supervision tree, without an explicit owner, shutdown policy, restart behavior or monitoring.

**Risk:** Orphan processes, unpredictable startup/shutdown ordering, silent failures and operational blind spots.

**Prefer:** Start long-lived workers via the application `Supervisor` or `DynamicSupervisor`; use `Task.Supervisor` for supervised tasks. Define an appropriate restart strategy and process ownership model.

```elixir
# Application-owned long-lived services:
children = [
  {Registry, keys: :unique, name: MyApp.Registry},
  {DynamicSupervisor, strategy: :one_for_one, name: MyApp.WorkerSupervisor}
]
Supervisor.start_link(children, strategy: :one_for_one)

# Per-request dynamic child (assuming MyApp.Worker implements child_spec/1):
DynamicSupervisor.start_child(MyApp.WorkerSupervisor, {MyApp.Worker, id: some_id})
```

**Do not flag:** Deliberately ephemeral, linked/monitored or short-lived processes with bounded scope and owned lifecycle. Consider task result handling and cancellation; `Task.start/1` alone does not provide full supervision.

## Practical OTP review questions

- What exact runtime concern requires each process? Who owns its lifecycle?
- Where are the public client APIs? Can another module bypass validation through raw messages?
- Which fields cross process boundaries? What is captured by closures?
- Can a mailbox grow without bound? Are expensive `handle_call` operations serialized?
- What happens when a worker crashes, hangs, or restarts? Is restart intensity appropriate?
- Does the supervisor start parents/dependencies in a valid order and shut them down safely?

## Non-official supplementary checks

The following are **useful adjacent review questions, not additional official catalog entries**: synchronous cyclic `GenServer.call`s, long-running work inside callbacks, missing call timeouts/overload handling, state persistence guarantees, graceful shutdown, and external side-effect idempotency. Evaluate them when relevant, but do not label them as one of the 25 official anti-patterns.
