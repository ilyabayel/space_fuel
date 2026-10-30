defmodule SpaceFuel.Missions.PresetsTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.Mission
  alias SpaceFuel.Missions.Planet
  alias SpaceFuel.Missions.Presets

  test "picker entries load valid missions and describe their route" do
    presets = Presets.all()
    assert length(Enum.uniq_by(presets, & &1.id)) == length(presets)

    for preset <- presets do
      assert Presets.fetch(preset.id) == preset
      steps = Enum.map(preset.steps, fn {action, planet} -> %{"action" => action, "planet" => planet} end)
      assert Mission.changeset(%Mission{}, %{"mass" => preset.mass, "steps" => steps}).valid?

      assert Presets.route_description(preset) ==
               preset.steps |> Enum.map(fn {_, planet} -> Planet.label(planet) end) |> Enum.dedup() |> Enum.join(" → ")
    end
  end
end
