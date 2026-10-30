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

  test "bounds raw inputs before casting and accounts for Ecto sort/drop expansion" do
    row = %{"action" => "launch", "planet" => "earth"}
    fifty = Enum.map(1..50, fn _ -> row end)
    assert Mission.changeset(%Mission{}, %{"mass" => "999999999999", "steps" => fifty}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => "1000000000000", "steps" => []}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => 1, "steps" => [row | fifty]}).valid?
    assert Mission.changeset(%Mission{}, %{"mass" => "1", "steps_sort" => List.duplicate("new", 50)}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => "1", "steps_sort" => List.duplicate("new", 51)}).valid?

    refute Mission.changeset(%Mission{}, %{
             "mass" => "1",
             "steps" => %{"0" => row},
             "steps_sort" => List.duplicate("new", 50)
           }).valid?

    refute Mission.changeset(%Mission{}, %{"mass" => "1", "steps_drop" => List.duplicate("0", 52)}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => "1", "steps_drop" => List.duplicate("0", 51)}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => "1", "steps" => nil}).valid?
    refute Mission.changeset(%Mission{}, %{"mass" => "1", "steps_sort" => nil}).valid?
    assert Mission.changeset(%Mission{}, %{"mass" => "1", "steps_drop" => ["" | Enum.map(0..49, &to_string/1)]}).valid?
  end

  test "rejects malformed fields and duplicate or invalid stage identifiers" do
    id = Ecto.UUID.generate()

    for attrs <- [
          %{"mass" => %{}},
          %{"mass" => "1", "steps" => [["bad"]]},
          %{"mass" => "1", "steps" => [%{"action" => %{}, "planet" => "earth"}]},
          %{"mass" => "1", "steps" => [%{"id" => "invalid"}]},
          %{"mass" => "1", "steps" => [%{"id" => id}, %{"id" => id}]}
        ] do
      changeset = Mission.changeset(%Mission{}, attrs)
      refute changeset.valid?
      assert changeset.params == nil
      assert is_binary(Mission.input_error(changeset))
    end
  end

  test "ordinary changeset errors are distinct from unsafe input rejections" do
    changeset = Mission.changeset(%Mission{}, %{"mass" => "0", "steps" => [%{"action" => "fly", "planet" => "earth"}]})
    refute changeset.valid?
    assert Mission.input_error(changeset) == nil
    assert changeset.params["mass"] == "0"
  end
end
