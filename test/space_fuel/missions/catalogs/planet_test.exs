defmodule SpaceFuel.Missions.Catalogs.PlanetTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "planet labels and display order remain stable" do
    assert Missions.planet_options() == [{"Earth", "earth"}, {"Moon", "moon"}, {"Mars", "mars"}]
  end

  test "gravity uses m/s² scaled by one thousand" do
    assert Missions.get_gravity("earth") == 9807
    assert Missions.get_gravity("moon") == 1620
    assert Missions.get_gravity("mars") == 3711
  end
end
