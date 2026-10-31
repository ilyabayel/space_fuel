defmodule SpaceFuel.Missions.Catalogs.ManeuverTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "maneuver labels and display order remain stable" do
    assert Missions.maneuver_options() == [{"Launch", "launch"}, {"Land", "land"}]
  end
end
