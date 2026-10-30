defmodule SpaceFuel.Missions.MissionTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.Maneuver
  alias SpaceFuel.Missions.Mission
  alias SpaceFuel.Missions.Planet

  test "mass must be a positive integer, even for empty routes" do
    for mass <- [1, "1", "28801"], do: assert(Mission.changeset(%Mission{}, %{"mass" => mass}).valid?)
    for mass <- [0, -10, "10.5", "", "abc", nil], do: refute(Mission.changeset(%Mission{}, %{"mass" => mass}).valid?)
  end

  test "validates fields without imposing sequence rules" do
    route = [
      %{"action" => "land", "planet" => "earth"},
      %{"action" => "land", "planet" => "mars"},
      %{"action" => "launch", "planet" => "moon"},
      %{"action" => "launch", "planet" => "earth"}
    ]

    assert Mission.changeset(%Mission{}, %{"mass" => 1, "steps" => route}).valid?

    for step <- [
          %{"action" => "fly", "planet" => "earth"},
          %{"action" => "land", "planet" => "pluto"},
          %{"planet" => "earth"},
          %{"action" => "launch"}
        ] do
      refute Mission.changeset(%Mission{}, %{"mass" => 1, "steps" => [step]}).valid?
    end
  end

  test "every catalog action and planet combination is accepted" do
    for {_label, action} <- Maneuver.options(), {_label, planet} <- Planet.options() do
      attrs = %{"mass" => 1000, "steps" => [%{"action" => action, "planet" => planet}]}
      assert Mission.changeset(%Mission{}, attrs).valid?
    end
  end
end
