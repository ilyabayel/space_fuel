defmodule SpaceFuel.Missions.Services.CalculateManeuverFuelTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.Missions

  test "launch includes successive fuel increments" do
    # A 1,000 kg launch on Earth needs increments of 378, 122, and 17 kg.
    assert Missions.calculate_maneuver_fuel("launch", 1000, Decimal.new("9.807")) == 517
  end

  test "landing includes successive fuel increments" do
    # A 1,000 kg landing on Earth needs increments of 281 and 48 kg.
    assert Missions.calculate_maneuver_fuel("land", 1000, Decimal.new("9.807")) == 329
    assert Missions.calculate_maneuver_fuel("land", 28_801, Decimal.new("9.807")) == 13_447
  end

  test "integer flooring preserves the first positive launch fuel threshold" do
    assert Missions.calculate_maneuver_fuel("launch", 82, Decimal.new("9.807")) == 0
    assert Missions.calculate_maneuver_fuel("launch", 83, Decimal.new("9.807")) == 1
  end

  test "integer flooring preserves the first positive landing fuel threshold" do
    assert Missions.calculate_maneuver_fuel("land", 132, Decimal.new("9.807")) == 0
    assert Missions.calculate_maneuver_fuel("land", 133, Decimal.new("9.807")) == 1
  end

  test "large calculations remain exact even with a lower caller precision" do
    Decimal.Context.with(%Decimal.Context{precision: 3}, fn ->
      assert Missions.calculate_maneuver_fuel("launch", 999_999_999_999, Decimal.new("9.807")) ==
               700_373_740_641

      assert Decimal.Context.get().precision == 3
    end)
  end

  test "zero and small masses terminate without negative fuel for every supported combination" do
    for {_label, action} <- Missions.maneuver_options(),
        {_label, planet} <- Missions.planet_options(),
        mass <- [0, 1] do
      assert Missions.calculate_maneuver_fuel(action, mass, Missions.get_gravity(planet)) == 0
    end
  end
end
