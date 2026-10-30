defmodule SpaceFuel.Missions.ManeuverTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.Maneuver
  alias SpaceFuel.Missions.Planet

  test "maneuver labels and display order remain stable" do
    assert Maneuver.options() == [{"Launch", "launch"}, {"Land", "land"}]
  end

  test "launch includes successive fuel increments" do
    # A 1,000 kg launch on Earth needs increments of 378, 122, and 17 kg.
    assert Maneuver.fuel_required("launch", 1000, 9807) == 517
  end

  test "landing includes successive fuel increments" do
    # A 1,000 kg landing on Earth needs increments of 281 and 48 kg.
    assert Maneuver.fuel_required("land", 1000, 9807) == 329
    assert Maneuver.fuel_required("land", 28_801, 9807) == 13_447
  end

  test "integer flooring preserves the first positive fuel thresholds" do
    assert Maneuver.fuel_required("launch", 82, 9807) == 0
    assert Maneuver.fuel_required("launch", 83, 9807) == 1
    assert Maneuver.fuel_required("land", 132, 9807) == 0
    assert Maneuver.fuel_required("land", 133, 9807) == 1
  end

  test "zero and small masses terminate without negative fuel for every supported combination" do
    for {_label, action} <- Maneuver.options(),
        {_label, planet} <- Planet.options(),
        mass <- [0, 1] do
      assert Maneuver.fuel_required(action, mass, Planet.gravity(planet)) == 0
    end
  end
end
