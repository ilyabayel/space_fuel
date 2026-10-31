defmodule SpaceFuel.Missions.Catalogs.PlanetTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "planet labels and display order remain stable" do
    assert Missions.planet_options() == [{"Earth", "earth"}, {"Moon", "moon"}, {"Mars", "mars"}]
  end

  test "gravity uses Decimal values in m/s²" do
    assert Missions.get_gravity("earth") == Decimal.new("9.807")
    assert Missions.get_gravity("moon") == Decimal.new("1.620")
    assert Missions.get_gravity("mars") == Decimal.new("3.711")
  end
end
