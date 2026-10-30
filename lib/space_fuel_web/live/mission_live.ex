defmodule SpaceFuelWeb.MissionLive do
  @moduledoc false
  use SpaceFuelWeb, :live_view

  import SpaceFuelWeb.MissionComponents

  alias SpaceFuel.Missions.FuelCalculator
  alias SpaceFuel.Missions.Mission

  @presets %{
    "apollo" => {"Apollo 11", 28_801, [{"launch", "earth"}, {"land", "moon"}, {"launch", "moon"}, {"land", "earth"}]},
    "mars" => {"Mars Mission", 14_606, [{"launch", "earth"}, {"land", "mars"}, {"launch", "mars"}, {"land", "earth"}]},
    "passenger" =>
      {"Passenger Ship", 75_432,
       [
         {"launch", "earth"},
         {"land", "moon"},
         {"launch", "moon"},
         {"land", "mars"},
         {"launch", "mars"},
         {"land", "earth"}
       ]}
  }

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.dashboard form={@form} result={@result} preset={@preset} mission_name={@mission_name} />
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket), do: {:ok, load_preset(socket, "apollo")}

  def handle_event("validate", %{"mission" => params}, socket) when is_map(params) do
    {:noreply,
     socket |> assign(:preset, "custom") |> assign(:mission_name, "Custom mission") |> update_mission(params, true)}
  rescue
    Ecto.CastError -> {:noreply, socket}
    ArgumentError -> {:noreply, socket}
  end

  def handle_event("preset", %{"name" => name}, socket) when is_map_key(@presets, name),
    do: {:noreply, load_preset(socket, name)}

  def handle_event("reset", _, socket), do: {:noreply, load_preset(socket, "apollo")}
  def handle_event(_, _, socket), do: {:noreply, socket}

  defp load_preset(socket, key) do
    {name, mass, steps} = Map.fetch!(@presets, key)

    params = %{
      "mass" => mass,
      "steps" => Enum.map(steps, fn {action, planet} -> %{"action" => action, "planet" => planet} end)
    }

    socket |> assign(:preset, key) |> assign(:mission_name, name) |> update_mission(params, false)
  end

  defp update_mission(socket, params, validate?) do
    changeset = Mission.changeset(%Mission{}, params)

    result =
      if changeset.valid?,
        do: changeset |> Ecto.Changeset.apply_changes() |> then(&FuelCalculator.calculate(&1.mass, &1.steps))

    changeset = if validate?, do: Map.put(changeset, :action, :validate), else: changeset
    socket |> assign(:form, to_form(changeset)) |> assign(:result, result)
  end
end
