defmodule SpaceFuelWeb.MissionComponents do
  @moduledoc false
  use SpaceFuelWeb, :html

  alias Phoenix.HTML.Form
  alias SpaceFuel.Missions

  attr :form, Form, required: true
  attr :result, :any, required: true
  attr :preset, :string, required: true
  attr :mission_name, :string, required: true

  attr :rejection, :string, default: nil

  def dashboard(assigns) do
    ~H"""
    <div class="app-shell">
      <header class="topbar">
        <a href="/" class="brand"><span class="brand-mark">✦</span> Space<span>Fuel</span></a>
        <div class="topbar-center">
          <span class="status-dot"></span>
          MISSION PLANNING SYSTEM <span class="topbar-divider">/</span>
          FUEL CALCULATOR
        </div>
        <div class="topbar-right">
          <span class="status-dot"></span>
          SYSTEM ONLINE <span class="topbar-divider">|</span> <span>UNITS <strong>KG</strong></span>
        </div>
      </header>
      <main class="workspace">
        <div class="intro">
          <div>
            <div class="eyebrow">
              <span class="status-dot"></span> MISSION CONTROL <span class="slash">/</span> PLANNING
            </div><h1>Fuel your next mission<span>.</span></h1><p>
              Plot your course. Know exactly what it takes to get there.
            </p>
          </div>
          <div class="intro-meta">
            <span>FLIGHT PLANNER</span><strong>01 <span>/ 03</span></strong>
          </div>
        </div>
        <.preset_picker preset={@preset} />
        <.mission_visualization result={@result} />
        <div class="main-grid">
          <.mission_form form={@form} rejection={@rejection} />
          <.fuel_results result={@result} mission_name={@mission_name} rejection={@rejection} />
        </div>
        <footer>
          <span>SPACEFUEL <span class="footer-sep">/</span> MISSION PLANNING SYSTEM</span><span>BUILT FOR THE JOURNEY AHEAD
          <span class="footer-star">✦</span></span>
        </footer>
      </main>
    </div>
    """
  end

  attr :preset, :string, required: true

  defp preset_picker(assigns) do
    ~H"""
    <section class="preset-section" aria-labelledby="preset-heading">
      <div class="section-heading">
        <div>
          <span class="section-index">01</span><h2 id="preset-heading">MISSION PRESETS</h2>
        </div><span>SELECT A MISSION TO GET STARTED</span>
      </div>
      <div class="presets">
        <button
          :for={item <- Missions.presets()}
          type="button"
          id={"preset-#{item.id}"}
          phx-click="preset"
          phx-value-name={item.id}
          class={["preset", @preset == item.id && "active"]}
          aria-pressed={to_string(@preset == item.id)}
        >
          <span class={["preset-orb", "orb-#{item.id}"]} aria-hidden="true">{item.icon}</span><span class="preset-copy"><strong>{item.name}</strong><small>{Missions.preset_route_description(
            item
          )}</small></span><span class="preset-radio" aria-hidden="true"></span>
        </button>
      </div>
    </section>
    """
  end

  attr :form, Form, required: true
  attr :rejection, :string, default: nil

  defp mission_form(assigns) do
    ~H"""
    <section class="panel editor" aria-labelledby="editor-heading">
      <div class="panel-head">
        <div>
          <span class="section-index">02</span><h2 id="editor-heading">
            MISSION CONFIGURATION
          </h2>
        </div><button type="button" id="reset-mission" phx-click="reset" class="text-action"><.icon
          name="hero-arrow-path"
          class="size-4"
        /> Reset</button>
      </div>
      <.form
        for={@form}
        id="mission-form"
        phx-change="validate"
        phx-submit="validate"
        class="mission-form"
      >
        <div class="field-heading">
          <div>
            <span class="field-icon"><.icon name="hero-cube" class="size-5" /></span><div>
              <h3>Spacecraft mass</h3><p>Mass of the spacecraft without fuel</p>
            </div>
          </div><span class="field-number">01</span>
        </div>
        <div class="mass-wrap">
          <.input
            field={@form[:mass]}
            type="number"
            min="1"
            max={Missions.max_mass()}
            step="1"
            label="SPACECRAFT MASS"
            class="mass-input"
          /><span class="unit">kg</span>
        </div>
        <div class="route-heading">
          <div class="field-heading">
            <div>
              <span class="field-icon"><.icon name="hero-map" class="size-5" /></span><div>
                <h3>Flight path</h3><p>Build your route in flight order</p>
              </div>
            </div><span class="field-number">02</span>
          </div>
        </div>
        <p :if={@rejection} id="mission-rejection" class="mission-error" role="alert">{@rejection}</p>
        <p :for={{message, _opts} <- @form[:steps].errors} class="mission-error">{message}</p>
        <div id="flight-steps" class="flight-step-list">
          <.inputs_for :let={step} field={@form[:steps]}>
            <div class="step-row" id={"step-#{step[:id].value}"}>
              <input type="hidden" name={step[:id].name} value={step[:id].value} />
              <input type="hidden" name="mission[steps_sort][]" value={step.index} />
              <span class="step-index">{String.pad_leading(to_string(step.index + 1), 2, "0")}</span>
              <div class="step-fields">
                <.input
                  field={step[:action]}
                  type="select"
                  label="MANEUVER"
                  options={Missions.maneuver_options()}
                  class="step-select"
                /><.input
                  field={step[:planet]}
                  type="select"
                  label="PLANET"
                  options={Missions.planet_options()}
                  class="step-select"
                />
              </div>
              <button
                type="button"
                phx-click={JS.dispatch("change")}
                name="mission[steps_drop][]"
                value={step.index}
                id={"remove-step-#{step.index}"}
                class="remove-step"
                aria-label={"Remove stage #{step.index + 1}"}
              ><.icon name="hero-trash" class="size-4" /></button>
            </div>
          </.inputs_for>
        </div>
        <input type="hidden" name="mission[steps_drop][]" value="" />
        <button
          type="button"
          phx-click={JS.dispatch("change")}
          name="mission[steps_sort][]"
          value="new"
          id="add-step"
          disabled={
            length(Ecto.Changeset.get_field(@form.source, :steps) || []) >= Missions.max_steps()
          }
          class="add-step"
        ><.icon name="hero-plus" class="size-4" /> Add flight stage</button>
      </.form>
      <div class="editor-note">
        <.icon name="hero-information-circle" class="size-4" />
        Stages are calculated in the order shown above.
      </div>
    </section>
    """
  end

  attr :result, :any, required: true
  attr :mission_name, :string, required: true
  attr :rejection, :string, default: nil

  defp fuel_results(assigns) do
    ~H"""
    <section class="panel results" aria-labelledby="results-heading" aria-live="polite">
      <div class="panel-head">
        <div>
          <span class="section-index">03</span><h2 id="results-heading">FUEL REQUIREMENTS</h2>
        </div><span class="live-label"><span class="status-dot"></span> LIVE CALCULATION</span>
      </div>
      <%= if @result do %>
        <div id="fuel-result" class="result-hero">
          <div class="result-label">
            <.icon name="hero-bolt" class="size-4" /> TOTAL FUEL REQUIRED
          </div><div class="total">{format_number(@result.total_fuel)} <span>kg</span></div><p>
            Fuel required to complete your flight path
          </p><div class="fuel-bar"><span></span><span></span><span></span></div><div class="result-stats">
            <div><span>MISSION</span><strong>{@mission_name}</strong></div><div>
              <span>FLIGHT STAGES</span><strong>{length(@result.steps)
              |> to_string()
              |> String.pad_leading(2, "0")}</strong>
            </div><div><span>CALCULATION</span><strong class="ready">● READY</strong></div>
          </div>
        </div>
        <div class="breakdown-head">
          <div>
            <h3>Stage breakdown</h3><p>Fuel required for each maneuver</p>
          </div><span>IN FLIGHT ORDER</span>
        </div>
        <div id="breakdown" class="breakdown">
          <%= if @result.steps == [] do %>
            <div id="empty-route" class="empty-state">
              No flight stages yet. Add a stage to plot your mission.
            </div>
          <% end %>
          <div
            :for={{step, index} <- Enum.with_index(@result.steps, 1)}
            id={"result-step-#{index}"}
            class="breakdown-row"
          >
            <span class="result-index">{String.pad_leading(to_string(index), 2, "0")}</span><span class={[
              "planet-dot",
              "planet-#{step.planet}"
            ]}></span><div class="stage-name">
              <strong>{Missions.maneuver_label(step.action)} {Missions.planet_label(step.planet)}</strong><small>Effective mass · {format_number(
                step.effective_mass
              )} kg</small>
            </div><div class="stage-fuel">
              <strong>{format_number(step.fuel)} <small>kg</small></strong><span>FUEL REQUIRED</span>
            </div>
          </div>
        </div>
      <% else %>
        <div id="result-unavailable" class="unavailable">
          <.icon name="hero-exclamation-circle" class="size-8" /><h3>
            Calculation unavailable
          </h3><p>
            {if @rejection,
              do: "Correct the rejected input to calculate your fuel requirements.",
              else: "Check the highlighted fields to calculate your fuel requirements."}
          </p>
        </div>
      <% end %>
    </section>
    """
  end

  attr :result, :any, required: true

  def mission_visualization(assigns) do
    ~H"""
    <section
      id="mission-visualization"
      class="panel visualization"
      aria-labelledby="visualization-heading"
    >
      <div class="panel-head">
        <div>
          <span class="visualization-icon"><.icon name="hero-globe-alt" class="size-4" /></span>
          <h2 id="visualization-heading">MISSION VISUALIZATION</h2>
        </div>
        <span class="visualization-mode"><span class="status-dot"></span> ROUTE SCHEMATIC</span>
      </div>
      <div class="visualization-space">
        <%= cond do %>
          <% is_nil(@result) -> %>
            <div id="visualization-unavailable" class="visualization-empty">
              <.icon name="hero-exclamation-circle" class="size-6" />
              <strong>Route unavailable</strong>
              <span>Check your mission inputs to see the route.</span>
            </div>
          <% @result.steps == [] -> %>
            <div id="visualization-empty" class="visualization-empty">
              <.icon name="hero-map" class="size-6" />
              <strong>Your flight path is empty</strong>
              <span>Add a flight stage to plot your route.</span>
            </div>
          <% true -> %>
            <div
              class="route-scroll"
              tabindex="0"
              aria-label="Mission route, scroll horizontally to see all stages"
            >
              <ol id="visualization-route" class="visualization-route">
                <li
                  :for={{step, index} <- Enum.with_index(@result.steps, 1)}
                  id={"visual-stage-#{index}"}
                  class="visual-stage"
                >
                  <span :if={index > 1} class="visual-connector" aria-hidden="true"><span>›</span></span>
                  <span class="visual-stage-number">{index}</span>
                  <span class={["visual-planet", "visual-planet-#{step.planet}"]} aria-hidden="true"><span></span></span>
                  <strong>{Missions.maneuver_label(step.action)} {Missions.planet_label(step.planet)}</strong>
                  <span class="visual-stage-caption">STAGE {String.pad_leading(
                    to_string(index),
                    2,
                    "0"
                  )}</span>
                </li>
              </ol>
            </div>
        <% end %>
        <div class="visualization-footer">
          <span><span class="visual-line-key"></span> FLIGHT ORDER</span><span>SCHEMATIC · NOT TO SCALE</span>
        </div>
      </div>
    </section>
    """
  end

  defp format_number(number) do
    number |> Integer.to_string() |> String.reverse() |> String.replace(~r/(\d{3})(?=\d)/, "\\1,") |> String.reverse()
  end
end
