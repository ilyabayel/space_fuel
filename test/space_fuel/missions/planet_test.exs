defmodule SpaceFuel.Missions.PlanetTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.Planet

  test "planet labels and display order remain stable" do
    assert Planet.options() == [{"Earth", "earth"}, {"Moon", "moon"}, {"Mars", "mars"}]
  end

  test "gravity uses m/s² scaled by one thousand" do
    assert Planet.gravity("earth") == 9807
    assert Planet.gravity("moon") == 1620
    assert Planet.gravity("mars") == 3711
  end
end
