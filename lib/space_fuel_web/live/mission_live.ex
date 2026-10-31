defmodule SpaceFuelWeb.MissionLive do
  @moduledoc false
  use SpaceFuelWeb, :live_view

  import SpaceFuelWeb.MissionComponents

  alias SpaceFuel.Missions

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

    changeset = Missions.change_mission(attrs)

    case Missions.get_input_error(changeset) do
      nil ->
        {:noreply,
         socket |> assign(:preset, "custom") |> assign(:mission_name, "Custom mission") |> update_mission(changeset, true)}

      message ->
        {:noreply, assign(socket, result: nil, rejection: message)}
    end
  end

  def handle_event("preset", %{"name" => name}, socket) do
    case Missions.get_preset(name) do
      nil -> {:noreply, socket}
      _preset -> {:noreply, load_preset(socket, name)}
    end
  end

  def handle_event("reset", _, socket), do: {:noreply, load_preset(socket, "apollo")}
  def handle_event(_, _, socket), do: {:noreply, socket}

  defp load_preset(socket, key) do
    preset = Missions.get_preset(key)

    params = %{
      "mass" => preset.mass,
      "steps" => Enum.map(preset.steps, fn {action, planet} -> %{"action" => action, "planet" => planet} end)
    }

    changeset = Missions.change_mission(params)
    socket |> assign(:preset, key) |> assign(:mission_name, preset.name) |> update_mission(changeset, false)
  end

  defp update_mission(socket, changeset, validate?) do
    result = mission_result(changeset)
    changeset = mark_for_validation(changeset, validate?)
    socket |> assign(:form, to_form(changeset)) |> assign(:result, result) |> assign(:rejection, nil)
  end

  defp mission_result(changeset) do
    if changeset.valid? do
      Missions.calculate_mission(changeset)
    end
  end

  defp mark_for_validation(changeset, validate?) do
    if validate? do
      Map.put(changeset, :action, :validate)
    else
      changeset
    end
  end
end
