defmodule SpaceFuel.Missions.FuelCalculatorTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions.FuelCalculator

  defp steps(pairs), do: Enum.map(pairs, fn {action, planet} -> %{action: action, planet: planet} end)
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
      result = FuelCalculator.calculate(mass, steps(route))
      assert result.total_fuel == expected
      assert Enum.sum(Enum.map(result.steps, & &1.fuel)) == expected
      assert Enum.map(result.steps, &{&1.action, &1.planet}) == route
    end

    assert List.last(FuelCalculator.calculate(28_801, steps(@apollo)).steps).fuel == 13_447
  end

  test "empty and small stages terminate without negative fuel" do
    assert FuelCalculator.calculate(1, []).total_fuel == 0

    for action <- ~w(launch land), planet <- ~w(earth moon mars) do
      assert FuelCalculator.calculate(1, steps([{action, planet}])).total_fuel == 0
    end
  end

  test "arbitrary order is preserved and fuel is monotonic" do
    route = steps([{"land", "earth"}, {"land", "mars"}, {"launch", "earth"}, {"launch", "earth"}])
    low = FuelCalculator.calculate(1_000, route)
    high = FuelCalculator.calculate(1_001, route)
    assert Enum.map(low.steps, &{&1.action, &1.planet}) == Enum.map(route, &{&1.action, &1.planet})
    assert high.total_fuel >= low.total_fuel
    assert Enum.all?(low.steps, &(&1.fuel >= 0))
    assert low == FuelCalculator.calculate(1_000, route)
  end

  test "floor boundary for a single landing" do
    assert FuelCalculator.calculate(132, steps([{"land", "earth"}])).total_fuel == 0
    assert FuelCalculator.calculate(133, steps([{"land", "earth"}])).total_fuel == 1
  end
end
