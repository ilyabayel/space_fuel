defmodule SpaceFuel.Missions.PresetsTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "picker entries load valid missions and describe their route" do
    presets = Missions.presets()
    assert length(Enum.uniq_by(presets, & &1.id)) == length(presets)

    for preset <- presets do
      assert Missions.get_preset(preset.id) == preset
      steps = Enum.map(preset.steps, fn {action, planet} -> %{"action" => action, "planet" => planet} end)
      assert Missions.change_mission(%{"mass" => preset.mass, "steps" => steps}).valid?

      assert Missions.get_preset_route_description(preset) ==
               preset.steps
               |> Enum.map(fn {_, planet} -> Missions.get_planet_label(planet) end)
               |> Enum.dedup()
               |> Enum.join(" → ")
    end
  end
end
