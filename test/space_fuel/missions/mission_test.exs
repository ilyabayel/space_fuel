defmodule SpaceFuel.Missions.MissionTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "mass must be a positive integer, even for empty routes" do
    for mass <- [1, "1", "28801"], do: assert(Missions.change_mission(%{"mass" => mass}).valid?)
    for mass <- [0, -10, "10.5", "", "abc", nil], do: refute(Missions.change_mission(%{"mass" => mass}).valid?)
  end

  test "validates fields without imposing sequence rules" do
    route = [
      %{"action" => "land", "planet" => "earth"},
      %{"action" => "land", "planet" => "mars"},
      %{"action" => "launch", "planet" => "moon"},
      %{"action" => "launch", "planet" => "earth"}
    ]

    assert Missions.change_mission(%{"mass" => 1, "steps" => route}).valid?

    for step <- [
          %{"action" => "fly", "planet" => "earth"},
          %{"action" => "land", "planet" => "pluto"},
          %{"planet" => "earth"},
          %{"action" => "launch"}
        ] do
      refute Missions.change_mission(%{"mass" => 1, "steps" => [step]}).valid?
    end
  end

  test "every catalog action and planet combination is accepted" do
    for {_label, action} <- Missions.maneuver_options(), {_label, planet} <- Missions.planet_options() do
      attrs = %{"mass" => 1000, "steps" => [%{"action" => action, "planet" => planet}]}
      assert Missions.change_mission(attrs).valid?
    end
  end

  test "bounds raw inputs before casting and accounts for Ecto sort/drop expansion" do
    row = %{"action" => "launch", "planet" => "earth"}
    fifty = Enum.map(1..50, fn _ -> row end)
    assert Missions.change_mission(%{"mass" => "999999999999", "steps" => fifty}).valid?
    refute Missions.change_mission(%{"mass" => "1000000000000", "steps" => []}).valid?
    refute Missions.change_mission(%{"mass" => 1, "steps" => [row | fifty]}).valid?
    assert Missions.change_mission(%{"mass" => "1", "steps_sort" => List.duplicate("new", 50)}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_sort" => List.duplicate("new", 51)}).valid?

    refute Missions.change_mission(%{
             "mass" => "1",
             "steps" => %{"0" => row},
             "steps_sort" => List.duplicate("new", 50)
           }).valid?

    refute Missions.change_mission(%{"mass" => "1", "steps_drop" => List.duplicate("0", 52)}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_drop" => List.duplicate("0", 51)}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps" => nil}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_sort" => nil}).valid?
    assert Missions.change_mission(%{"mass" => "1", "steps_drop" => ["" | Enum.map(0..49, &to_string/1)]}).valid?
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
      changeset = Missions.change_mission(attrs)
      refute changeset.valid?
      assert changeset.params == nil
      assert is_binary(Missions.input_error(changeset))
    end
  end

  test "ordinary changeset errors are distinct from unsafe input rejections" do
    changeset = Missions.change_mission(%{"mass" => "0", "steps" => [%{"action" => "fly", "planet" => "earth"}]})
    refute changeset.valid?
    assert Missions.input_error(changeset) == nil
    assert changeset.params["mass"] == "0"
  end

  test "atom and browser string keys produce equivalent missions and preserve unused-field metadata" do
    atom_attrs = %{
      mass: "1000",
      _unused_mass: "",
      steps: %{"0" => %{action: "launch", planet: "earth", _unused_action: ""}},
      steps_sort: ["0"]
    }

    string_attrs = %{
      "mass" => "1000",
      "_unused_mass" => "",
      "steps" => %{"0" => %{"action" => "launch", "planet" => "earth", "_unused_action" => ""}},
      "steps_sort" => ["0"]
    }

    for attrs <- [atom_attrs, string_attrs] do
      changeset = Missions.change_mission(attrs)
      assert changeset.valid?
      assert changeset.params["_unused_mass"] == ""
      assert [step] = Ecto.Changeset.get_change(changeset, :steps)
      assert step.params["_unused_action"] == ""
      assert Missions.calculate_mission(changeset).total_fuel == 517
    end
  end
end
