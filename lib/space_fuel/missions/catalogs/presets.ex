defmodule SpaceFuel.Missions.Catalogs.Presets do
  @moduledoc "Ordered reference missions and their picker metadata."

  alias SpaceFuel.Missions.Catalogs.Planet

  @presets [
    %{
      id: "apollo",
      name: "Apollo 11",
      planets: ["moon"],
      mass: 28_801,
      steps: [{"launch", "earth"}, {"land", "moon"}, {"launch", "moon"}, {"land", "earth"}]
    },
    %{
      id: "mars",
      name: "Mars Mission",
      planets: ["mars"],
      mass: 14_606,
      steps: [{"launch", "earth"}, {"land", "mars"}, {"launch", "mars"}, {"land", "earth"}]
    },
    %{
      id: "passenger",
      name: "Passenger Ship",
      planets: ["moon", "mars"],
      mass: 75_432,
      steps: [
        {"launch", "earth"},
        {"land", "moon"},
        {"launch", "moon"},
        {"land", "mars"},
        {"launch", "mars"},
        {"land", "earth"}
      ]
    }
  ]

  def presets, do: @presets
  def get(id), do: Enum.find(@presets, &(&1.id == id))

  def get_route_description(preset) do
    preset.steps
    |> Enum.map(fn {_action, planet} -> Planet.get_label(planet) end)
    |> Enum.dedup()
    |> Enum.join(" → ")
  end
end
