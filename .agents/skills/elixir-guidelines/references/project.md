# Project Elixir, Mix, and test rules

These are this repository's requirements. Project preferences below are distinct from the linked language and library contracts. They take precedence over community style preferences.

## Completion and dependencies

- Run the existing `mix precommit` alias when finishing changes. Inspect its definition in
  `mix.exs`: aliases can run multiple tasks, including tasks that format source or update a lockfile.
  Fix failures introduced by the current changes. Report unrelated existing failures or environment
  blockers with the failing command; keep unrelated repairs outside the task's scope.
- Prefer `Req` for application HTTP requests rather than adding HTTPoison, Tesla, or direct `:httpc`
  calls. This is a project preference, not a Phoenix dependency guarantee. Check `mix.exs` and
  `mix.lock` before using it. If HTTP work needs it and it is absent, add an explicit dependency
  within the authorized task rather than assuming it exists.
- Use standard `Time`, `Date`, `DateTime`, and `Calendar` APIs for supported date/time operations.
  Check available parsers and the configured time-zone database before adding a dependency.
  Add dependencies only when the task requires them or the user requests them; date parsing alone
  does not mandate a particular third-party package.

Sources: [Mix aliases](https://mix.hexdocs.pm/Mix.html#module-aliases),
[Req setup](https://req.hexdocs.pm/readme.html), and this repository's `mix.exs`/`mix.lock`.
The choice of HTTP client and the boundary for unrelated repairs are local workflow policy.

## Elixir data and scope

- Use `Enum.at/2`, pattern matching, or `List` functions for positional list access. `list[index]`
  does not implement indexed access; Access supports keyword-list keys instead.
- Rebinding a variable inside `if`, `case`, or `cond` does not update an outer binding. Assign the
  expression's result, and return a valid value on every branch. An `if` without `else` returns
  `nil` when its condition is false.

```elixir
socket =
  if connected?(socket) do
    assign(socket, :val, val)
  else
    socket
  end
```

- Keep one module per file as a project organization rule. Nested modules are legal Elixir;
  module nesting by itself is not evidence of a cyclic dependency.
- Use `struct.field` or the struct's public API for field access, unless it explicitly implements
  `Access`. For changesets, use `Ecto.Changeset.get_field/2`; for `Phoenix.HTML.Form`,
  `form[:field]` is supported. Avoid treating all structs as interchangeable maps.
- Keep unbounded user input as strings or validate it against a bounded lookup; avoid
  `String.to_atom/1` on untrusted data. See [code.md](code.md#4-dynamic-atom-creation).
- Give ordinary boolean predicates a trailing `?`; reserve `is_` for guard-compatible checks.

Sources: [Access](https://elixir.hexdocs.pm/Access.html),
[if](https://elixir.hexdocs.pm/Kernel.html#if/2),
[variable scope](https://elixir.hexdocs.pm/case-cond-and-if.html),
[changeset field access](https://ecto.hexdocs.pm/Ecto.Changeset.html#get_field/3), and
[form field access](https://phoenix-html.hexdocs.pm/Phoenix.HTML.Form.html).

## OTP names and concurrent work

- `DynamicSupervisor` may be unnamed and addressed by PID. Give it a `:name` when stable name-based
  lookup is needed. `Registry.start_link/1` requires both `:name` and `:keys`; choose `:unique` or
  `:duplicate` to match the registration contract.

```elixir
children = [
  {Registry, keys: :unique, name: SpaceFuel.WorkerRegistry},
  {DynamicSupervisor, strategy: :one_for_one, name: SpaceFuel.WorkerSupervisor}
]
```

- Use `Task.async_stream/3` when concurrent processing is justified. Set concurrency and timeout
  according to workload and external-service limits. Its default per-task timeout is 5,000 ms;
  a timeout exits the caller by default. Use `on_timeout: :kill_task` when timed-out tasks should
  produce `{:exit, :timeout}` results, and handle those results explicitly.
- Choose `timeout: :infinity` only when indefinite waiting is intentional or another layer provides
  the required deadline/cancellation. `on_timeout` cannot bound a task when its timeout is infinite.
  For task-crash isolation, consider `Task.Supervisor.async_stream_nolink` and handle failures;
  `Task.async_stream` links task execution to the caller.

Sources: [DynamicSupervisor.start_link/1](https://elixir.hexdocs.pm/DynamicSupervisor.html#start_link/1),
[Registry.start_link/1](https://elixir.hexdocs.pm/Registry.html#start_link/1), and
[Task.async_stream options](https://elixir.hexdocs.pm/Task.html#async_stream/5).

## Mix and test process lifecycle

- Read `mix help task_name` before using an unfamiliar task or option. To isolate test failures,
  run the relevant test file or `mix test --failed`. Use `mix deps.clean --all` only with a
  demonstrated need; it is not a routine debugging step.
- Start test-owned OTP services with `start_supervised!/1` so ExUnit manages cleanup. For
  deliberately short-lived tasks or raw processes, establish explicit ownership and cleanup.
- Synchronize on observable events rather than `Process.sleep/1` or a racy `Process.alive?/1` check.
  Establish a monitor before triggering the exit you want to observe, then assert the expected
  `:DOWN` reason. Observing one PID's exit does not establish whether a supervisor restarted a child.

```elixir
ref = Process.monitor(pid)
send(pid, :finish)
assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
```

The example assumes the worker handles `:finish` by exiting normally.

- For an ordinary, unsuspended GenServer using its normal mailbox loop, a synchronous call from the
  test can establish that earlier ordinary messages from that same test process were handled.
  `:sys.get_state(pid)` can serve that purpose when no suitable public synchronization API exists.
  This relies on the normal message ordering and receive behavior, not a global completion barrier.
  It does not wait for messages from other senders, deferred work, spawned tasks, priority-message
  reordering, or a suspended server's ordinary mailbox. Use an explicit completion reply/event for
  those cases.

Sources: [ExUnit process supervision](https://ex-unit.hexdocs.pm/ExUnit.Callbacks.html#start_supervised/2),
[Process.monitor/1](https://elixir.hexdocs.pm/Process.html#monitor/1),
[Erlang signal ordering and mailbox behavior](https://www.erlang.org/doc/system/ref_man_processes.html#signals),
and [sys.get_state](https://www.erlang.org/doc/apps/stdlib/sys.html#get_state/1).
