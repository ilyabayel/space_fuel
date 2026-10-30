defmodule SpaceFuel.Missions.ManeuverTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "maneuver labels and display order remain stable" do
    assert Missions.maneuver_options() == [{"Launch", "launch"}, {"Land", "land"}]
  end

  test "launch includes successive fuel increments" do
    # A 1,000 kg launch on Earth needs increments of 378, 122, and 17 kg.
    assert Missions.calculate_maneuver_fuel("launch", 1000, 9807) == 517
  end

  test "landing includes successive fuel increments" do
    # A 1,000 kg landing on Earth needs increments of 281 and 48 kg.
    assert Missions.calculate_maneuver_fuel("land", 1000, 9807) == 329
    assert Missions.calculate_maneuver_fuel("land", 28_801, 9807) == 13_447
  end

  test "integer flooring preserves the first positive fuel thresholds" do
    assert Missions.calculate_maneuver_fuel("launch", 82, 9807) == 0
    assert Missions.calculate_maneuver_fuel("launch", 83, 9807) == 1
    assert Missions.calculate_maneuver_fuel("land", 132, 9807) == 0
    assert Missions.calculate_maneuver_fuel("land", 133, 9807) == 1
  end

  test "zero and small masses terminate without negative fuel for every supported combination" do
    for {_label, action} <- Missions.maneuver_options(),
        {_label, planet} <- Missions.planet_options(),
        mass <- [0, 1] do
      assert Missions.calculate_maneuver_fuel(action, mass, Missions.get_gravity(planet)) == 0
    end
  end
end
