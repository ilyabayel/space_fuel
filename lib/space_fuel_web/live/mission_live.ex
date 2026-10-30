defmodule SpaceFuelWeb.MissionLive do
  @moduledoc false
  use SpaceFuelWeb, :live_view

  import SpaceFuelWeb.MissionComponents

  alias SpaceFuel.Missions.FuelCalculator
  alias SpaceFuel.Missions.Mission
  alias SpaceFuel.Missions.Presets

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.dashboard
        form={@form}
        result={@result}
        preset={@preset}
        mission_name={@mission_name}
        rejection={@rejection}
      />
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket), do: {:ok, load_preset(socket, "apollo")}

  def handle_event("validate", params, socket) do
    attrs =
      case params do
        %{"mission" => mission} -> mission
        _ -> nil
      end

    changeset = Mission.changeset(%Mission{}, attrs)

    case Mission.input_error(changeset) do
      nil ->
        {:noreply,
         socket |> assign(:preset, "custom") |> assign(:mission_name, "Custom mission") |> update_mission(changeset, true)}

      message ->
        {:noreply, assign(socket, result: nil, rejection: message)}
    end
  end

  def handle_event("preset", %{"name" => name}, socket) do
    case Presets.fetch(name) do
      nil -> {:noreply, socket}
      _preset -> {:noreply, load_preset(socket, name)}
    end
  end

  def handle_event("reset", _, socket), do: {:noreply, load_preset(socket, "apollo")}
  def handle_event(_, _, socket), do: {:noreply, socket}

  defp load_preset(socket, key) do
    preset = Presets.fetch(key)

    params = %{
      "mass" => preset.mass,
      "steps" => Enum.map(preset.steps, fn {action, planet} -> %{"action" => action, "planet" => planet} end)
    }

    changeset = Mission.changeset(%Mission{}, params)
    socket |> assign(:preset, key) |> assign(:mission_name, preset.name) |> update_mission(changeset, false)
  end

  defp update_mission(socket, changeset, validate?) do
    result =
      if changeset.valid?,
        do: changeset |> Ecto.Changeset.apply_changes() |> then(&FuelCalculator.calculate(&1.mass, &1.steps))

    changeset = if validate?, do: Map.put(changeset, :action, :validate), else: changeset
    socket |> assign(:form, to_form(changeset)) |> assign(:result, result) |> assign(:rejection, nil)
  end
end
