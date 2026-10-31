defmodule SpaceFuel.Missions.FuelCalculatorTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions
  alias SpaceFuel.Missions.Schemas.FlightStep

  defp build_steps(pairs), do: Enum.map(pairs, fn {action, planet} -> %{action: action, planet: planet} end)
  @apollo [{"launch", "earth"}, {"land", "moon"}, {"launch", "moon"}, {"land", "earth"}]
  @mars [{"launch", "earth"}, {"land", "mars"}, {"launch", "mars"}, {"land", "earth"}]
  @passenger [
    {"launch", "earth"},
    {"land", "moon"},
    {"launch", "moon"},
    {"land", "mars"},
    {"launch", "mars"},
    {"land", "earth"}
  ]

  test "reference missions" do
    scenarios = [{28_801, @apollo, 51_898}, {14_606, @mars, 33_388}, {75_432, @passenger, 212_161}]

    for {mass, route, expected} <- scenarios do
      result = Missions.calculate_fuel(mass, build_steps(route))
      assert result.total_fuel == expected
      assert Enum.sum(Enum.map(result.steps, & &1.fuel)) == expected
      assert Enum.map(result.steps, &{&1.action, &1.planet}) == route
    end

    assert List.last(Missions.calculate_fuel(28_801, build_steps(@apollo)).steps).fuel == 13_447
  end

  test "empty and small stages terminate without negative fuel" do
    assert Missions.calculate_fuel(1, []).total_fuel == 0

    for action <- ~w(launch land), planet <- ~w(earth moon mars) do
      assert Missions.calculate_fuel(1, build_steps([{action, planet}])).total_fuel == 0
    end
  end

  test "arbitrary order is preserved and fuel is monotonic" do
    route = build_steps([{"land", "earth"}, {"land", "mars"}, {"launch", "earth"}, {"launch", "earth"}])
    low = Missions.calculate_fuel(1_000, route)
    high = Missions.calculate_fuel(1_001, route)
    assert Enum.map(low.steps, &{&1.action, &1.planet}) == Enum.map(route, &{&1.action, &1.planet})
    assert high.total_fuel >= low.total_fuel
    assert Enum.all?(low.steps, &(&1.fuel >= 0))
    assert low == Missions.calculate_fuel(1_000, route)
  end

  test "floor boundary for a single landing" do
    assert Missions.calculate_fuel(132, build_steps([{"land", "earth"}])).total_fuel == 0
    assert Missions.calculate_fuel(133, build_steps([{"land", "earth"}])).total_fuel == 1
  end

  test "each stage carries the fuel required by every later stage" do
    mass = 28_801
    result = Missions.calculate_fuel(mass, build_steps(@apollo))

    for {stage, index} <- Enum.with_index(result.steps) do
      later_fuel = result.steps |> Enum.drop(index + 1) |> Enum.map(& &1.fuel) |> Enum.sum()
      assert stage.effective_mass == mass + later_fuel
    end
  end

  test "maps and embedded flight steps produce identical results" do
    route = build_steps(@apollo)
    embedded_route = Enum.map(route, &struct!(FlightStep, &1))

    assert Missions.calculate_fuel(28_801, embedded_route) == Missions.calculate_fuel(28_801, route)
  end

  test "large and edited routes retain exact integer results" do
    assert Missions.calculate_fuel(999_999_999_999, build_steps(List.duplicate({"launch", "earth"}, 50))).total_fuel ==
             336_681_682_585_413_579_314_401

    assert Missions.calculate_fuel(28_801, build_steps(List.replace_at(@apollo, 1, {"launch", "mars"}))).total_fuel ==
             61_668

    assert Missions.calculate_fuel(1_000, build_steps(List.delete_at(@apollo, 1))).total_fuel == 1_155
  end
end
