# Project Phoenix, HEEx, and LiveView rules

## Phoenix v1.8 layouts and scope

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- `SpaceFuelWeb.Layouts` is aliased in `space_fuel_web.ex`; use the existing alias.
- Diagnose a missing `current_scope` by tracing the assign from the router pipeline or LiveView
  `on_mount` hook to the template and layout. With generated authentication, use the existing
  scope-mounting/authentication hooks in the appropriate `live_session`, and pass the scope to
  components that need it. Preserve the route's intended access policy.
- This repository currently has no generated auth pipeline/hooks, and `Layouts.app` declares
  `current_scope` with `default: nil`. Public views may omit that optional attribute. Add a scope
  producer or change session boundaries only when the feature's access requirements call for it;
  never suppress a missing scope on a protected route by substituting `nil`.
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- Check `core_components.ex` before overriding an input's classes. Its `class` attribute replaces
  the base input classes, so supply complete base styling; the component may still add error
  classes and wrapper/label styling. Configure `error_class` when that also needs to change.

Source: [Phoenix scopes and their mounting hooks](https://phoenix.hexdocs.pm/scopes.html).
Layout, icon, input, and flash placement are project conventions; inspect the local components.

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- Inside a `scope` that supplies a module alias, use relative route module names rather than
  duplicating that prefix. For example:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- Put shared template imports/aliases in the `html_helpers` block of `space_fuel_web.ex`, so
  modules using the corresponding `SpaceFuelWeb` definitions receive them.

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- Use list syntax when combining conditional class values. Static class strings and expressions
  returning a valid class value are also supported:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  Let the configured formatter handle parentheses and spacing in Elixir expressions.

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`

### LiveView streams

- Prefer streams for large or incrementally updated DOM collections when the server does not need
  to retain every rendered item. Ordinary assigns remain appropriate for small, bounded collections
  and data needed for server-side computation or form handling. For a stream, use:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: 0)`
  - deleting items - `stream_delete(socket, :messages, msg)`

  Prepending multiple items at index `0` reverses their order. Use
  `stream(socket, :messages, Enum.reverse(messages), at: 0)` to preserve the input order.

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- Stream assigns retain pending operations rather than the full rendered collection; consume them
  directly in the template comprehension, not through `Enum.filter/2` or `Enum.reject/2`. For a new
  filtered result set, query the data source (or use separately owned application data), then reset
  the stream. Individual removals can use `stream_delete/3` without resetting the whole collection:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         # reset the stream with the new messages
         |> stream(:messages, messages, reset: true)}
      end

- Do not derive the total displayed count or emptiness from pending stream operations. Track a
  count separately when needed. An empty-state node inside the stream container needs its own
  unique ID, just like every other direct child:

      <div id="tasks" phx-update="stream">
        <div id="tasks-empty" class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @streams.tasks} id={id}>
          {task.name}
        </div>
      </div>

  This CSS approach assumes the empty-state node is the only non-item child. Keep it in the DOM:
  non-stream children cannot be removed by conditional rendering once inserted, even after a reset.

- When a shared assign changes content inside streamed rows, re-insert every affected row with the
  new assign values. When editing switches from A to B, update both rows so A closes and B opens.
  The following excerpt assumes `editing_message_id: nil` and `edit_form: nil` are assigned on mount.
  It uses default stream DOM IDs. Context lookups must enforce the application's access policy.
  `Chat.get_message/1` returns the latest record or `nil` when it is no longer available:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        previous_id = socket.assigns.editing_message_id
        edit_form =
          message
          |> Chat.change_message(%{content: message.content})
          |> to_form(id: "edit-form-#{message.id}")

        socket =
          socket
          |> assign(:editing_message_id, message.id)
          |> assign(:edit_form, edit_form)

        socket =
          if previous_id && previous_id != message.id do
            case Chat.get_message(previous_id) do
              nil ->
                stream_delete(socket, :messages, %{id: previous_id})

              previous_message ->
                stream_insert(socket, :messages, previous_message, update_only: true)
            end
          else
            socket
          end

        {:noreply, stream_insert(socket, :messages, message, update_only: true)}
      end

  Template excerpt inside `<Layouts.app>`. The `update_only: true` operations assume the rows
  already exist on the client; they avoid re-inserting a row that has been removed:

      <div id="messages" phx-update="stream">
        <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
          {message.username}
          <%= if @editing_message_id == message.id do %>
            <%!-- Edit mode --%>
            <.form for={@edit_form} id={"edit-form-#{message.id}"} phx-submit="save_edit">
              <.input field={@edit_form[:content]} type="textarea" />
            </.form>
          <% end %>
        </div>
      </div>

  Handle save, cancel, and deletion similarly: clear or replace the editing state and re-insert
  the affected row if it still exists. Re-fetching the previous row avoids overwriting a concurrent
  update with a stale copy. Handle deletion events by removing the row from the stream as well.

Source: [stream operations, DOM requirements, and updates](https://phoenix-live-view.hexdocs.pm/1.2.0/Phoenix.LiveView.html#stream/4).
The choice between assigns and streams is an application design decision, not a blanket API rule.

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView JavaScript interop

- Remember anytime you use `phx-hook="MyHook"` and that JS hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Always** provide an unique DOM id alongside `phx-hook` otherwise a compiler error will be raised

LiveView hooks come in two flavors, 1) colocated js hooks for "inline" scripts defined inside HEEx,
and 2) external `phx-hook` annotations where JavaScript object literals are defined and passed to the `LiveSocket` constructor.

#### Inline colocated js hooks

**Never** write raw embedded `<script>` tags in heex as they are incompatible with LiveView.
Instead, **always use a colocated js hook script tag (`:type={Phoenix.LiveView.ColocatedHook}`)
when writing scripts inside the template**:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- colocated hooks are automatically integrated into the app.js bundle
- colocated hooks names **MUST ALWAYS** start with a `.` prefix, i.e. `.PhoneNumber`

#### External phx-hook

Place external hook definitions in `assets/js/` and merge them into the existing LiveSocket
configuration. Preserve colocated hooks and the existing connection options, including CSRF params:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      params: {_csrf_token: csrfToken},
      hooks: {...colocatedHooks, MyHook}
    });

#### Pushing events between client and server

Use LiveView's `push_event/3` when you need to push events/data to the client for a phx-hook to handle.
**Always** return or rebind the socket on `push_event/3` when pushing events:

    # re-bind socket so we maintain event state to be pushed
    socket = push_event(socket, "my_event", %{...})

    # or return the modified socket directly:
    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

Pushed events can then be picked up in a JS hook with `this.handleEvent`:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

Clients can also push an event to the server and receive a reply with `this.pushEvent`:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

Where the server handled it via:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Use stable element IDs to target interactions, then assert the user-visible result, relevant
  attributes, errors, or navigation. Text assertions are appropriate when the text is the behavior
  under test; element existence alone does not establish that a calculation or action succeeded.
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected
to have string keys. Both map-backed and changeset-backed forms are supported; use a changeset
when schema casting/validation or changeset errors are needed.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

The direct-changeset approach below is supported by Phoenix, but this project uses assigned
`to_form` results in LiveViews for change tracking and consistent field access:

    <%!-- Supported API; use the assigned-form convention above in this project. --%>
    <.form :let={f} for={@changeset} id="alternate-form">
      <.input field={f[:field]} type="text" />
    </.form>

- Keep casting and validation in the LiveView/context, and access input fields through `@form[:field]`.
  `Ecto.Changeset` itself does not implement Access, so `@changeset[:field]` is invalid even though
  passing a changeset to the form component is supported.
- Use `<.form for={@form} ...>` in LiveViews. Phoenix also supports `:let={f}` with a map or changeset,
  but recommends assigned forms for LiveView optimization. These are distinct from HTML's ordinary
  attributes; the slot-binding attribute is `:let`, not `let`.

Sources: [forms and change tracking](https://phoenix-live-view.hexdocs.pm/1.2.0/Phoenix.Component.html#form/1),
[to_form/2](https://phoenix-live-view.hexdocs.pm/1.2.0/Phoenix.Component.html#to_form/2),
[HEEx syntax](https://phoenix-live-view.hexdocs.pm/1.2.0/Phoenix.Component.html#sigil_H/2),
and [JavaScript hooks](https://phoenix-live-view.hexdocs.pm/1.2.0/js-interop.html#client-hooks-via-phx-hook).
<!-- phoenix:liveview-end -->
