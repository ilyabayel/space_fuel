defmodule SpaceFuel.Missions.Contracts.MissionParamsTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.Contracts.MissionParams

  test "rejects malformed stage indexes with the stage error" do
    for index <- [nil, 0, :invalid, String.duplicate("0", 65)] do
      assert MissionParams.validate(%{steps: %{index => %{}}}) ==
               {:error, {:steps, "Flight stages contain malformed values."}}
    end
  end

  test "rejects malformed stage shapes and field values with the stage error" do
    for step <- [nil, [], "invalid", MapSet.new(), %{action: %{}}, %{planet: String.duplicate("x", 65)}] do
      assert MissionParams.validate(%{steps: %{"0" => step}}) ==
               {:error, {:steps, "Flight stages contain malformed values."}}
    end
  end

  test "rejects malformed removal input with the removal error" do
    for drop <- [nil, %{}, "0", [0], [String.duplicate("0", 65)], List.duplicate("0", 52)] do
      assert MissionParams.validate(%{steps_drop: drop}) ==
               {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  test "rejects repeated empty removal markers and more than fifty removal identifiers" do
    for drop <- [["", ""], List.duplicate("0", 51)] do
      assert MissionParams.validate(%{steps_drop: drop}) ==
               {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  test "accepts up to fifty removal identifiers and one empty marker" do
    indexes = Enum.map(0..49, &Integer.to_string/1)

    for drop <- [[], [""], indexes, ["" | indexes]] do
      assert MissionParams.validate(%{steps_drop: drop}) == {:ok, %{steps_drop: drop}}
    end
  end
end
