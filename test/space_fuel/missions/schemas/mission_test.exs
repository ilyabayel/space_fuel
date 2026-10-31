defmodule SpaceFuel.Missions.Schemas.MissionTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "mass must be a positive integer, even for empty routes" do
    for mass <- [1, "1", "28801"], do: assert(Missions.change_mission(%{"mass" => mass}).valid?)
    for mass <- [0, -10, "10.5", "", "abc", nil], do: refute(Missions.change_mission(%{"mass" => mass}).valid?)
  end

  test "does not impose sequence rules" do
    route = [
      %{"action" => "land", "planet" => "earth"},
      %{"action" => "land", "planet" => "mars"},
      %{"action" => "launch", "planet" => "moon"},
      %{"action" => "launch", "planet" => "earth"}
    ]

    assert Missions.change_mission(%{"mass" => 1, "steps" => route}).valid?
  end

  test "rejects invalid and missing step fields" do
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

  test "accepts the maximum mass and number of steps" do
    row = %{"action" => "launch", "planet" => "earth"}
    fifty = Enum.map(1..50, fn _ -> row end)
    assert Missions.change_mission(%{"mass" => "999999999999", "steps" => fifty}).valid?
  end

  test "rejects mass above the limit" do
    refute Missions.change_mission(%{"mass" => "1000000000000", "steps" => []}).valid?
  end

  test "rejects more than fifty steps" do
    row = %{"action" => "launch", "planet" => "earth"}
    fifty = Enum.map(1..50, fn _ -> row end)
    refute Missions.change_mission(%{"mass" => 1, "steps" => [row | fifty]}).valid?
  end

  test "bounds new steps added by sorting" do
    assert Missions.change_mission(%{"mass" => "1", "steps_sort" => List.duplicate("new", 50)}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_sort" => List.duplicate("new", 51)}).valid?

    row = %{"action" => "launch", "planet" => "earth"}

    refute Missions.change_mission(%{
             "mass" => "1",
             "steps" => %{"0" => row},
             "steps_sort" => List.duplicate("new", 50)
           }).valid?
  end

  test "bounds dropped step identifiers" do
    refute Missions.change_mission(%{"mass" => "1", "steps_drop" => List.duplicate("0", 52)}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_drop" => List.duplicate("0", 51)}).valid?
    assert Missions.change_mission(%{"mass" => "1", "steps_drop" => ["" | Enum.map(0..49, &to_string/1)]}).valid?
  end

  test "rejects nil step and sort inputs" do
    refute Missions.change_mission(%{"mass" => "1", "steps" => nil}).valid?
    refute Missions.change_mission(%{"mass" => "1", "steps_sort" => nil}).valid?
  end

  defp malformed_attrs do
    id = Ecto.UUID.generate()

    [
      %{"mass" => %{}},
      %{"mass" => "1", "steps" => [["bad"]]},
      %{"mass" => "1", "steps" => [%{"action" => %{}, "planet" => "earth"}]},
      %{"mass" => "1", "steps" => [%{"id" => "invalid"}]},
      %{"mass" => "1", "steps" => [%{"id" => id}, %{"id" => id}]}
    ]
  end

  test "rejects malformed fields and duplicate or invalid stage identifiers" do
    for attrs <- malformed_attrs() do
      refute Missions.change_mission(attrs).valid?
    end
  end

  test "does not retain rejected unsafe input as changeset parameters" do
    for attrs <- malformed_attrs() do
      assert Missions.change_mission(attrs).params == nil
    end
  end

  test "unsafe input rejections provide an error message" do
    for attrs <- malformed_attrs() do
      assert is_binary(Missions.get_input_error(Missions.change_mission(attrs)))
    end
  end

  test "ordinary changeset errors do not produce an unsafe input error" do
    changeset = Missions.change_mission(%{"mass" => "0", "steps" => [%{"action" => "fly", "planet" => "earth"}]})
    refute changeset.valid?
    assert Missions.get_input_error(changeset) == nil
  end

  test "ordinary changeset errors retain input parameters" do
    changeset = Missions.change_mission(%{"mass" => "0", "steps" => [%{"action" => "fly", "planet" => "earth"}]})
    assert changeset.params["mass"] == "0"
  end

  defp equivalent_attrs do
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

    [atom_attrs, string_attrs]
  end

  test "atom and browser string keys produce equivalent mission calculations" do
    for attrs <- equivalent_attrs() do
      changeset = Missions.change_mission(attrs)
      assert changeset.valid?
      assert Missions.calculate_mission(changeset).total_fuel == 517
    end
  end

  test "atom and browser string keys preserve unused-field metadata" do
    for attrs <- equivalent_attrs() do
      changeset = Missions.change_mission(attrs)
      assert changeset.params["_unused_mass"] == ""
      assert [step] = Ecto.Changeset.get_change(changeset, :steps)
      assert step.params["_unused_action"] == ""
    end
  end
end
