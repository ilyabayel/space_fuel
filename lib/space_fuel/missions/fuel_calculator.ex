defmodule SpaceFuel.Missions.FuelCalculator do
  @moduledoc """
  Accumulates fuel requirements backwards through a validated mission.

  Each stage carries the spacecraft's dry mass plus fuel for all later stages.
  Planet gravity and maneuver fuel rules are delegated to their domain modules;
  results are returned in flight order. This module is independent of Ecto and
  Phoenix and assumes callers have validated mass and step identifiers.
  """

  alias SpaceFuel.Missions.Maneuver
  alias SpaceFuel.Missions.Planet
  alias SpaceFuel.Missions.Result

  @doc """
  Calculates fuel for a positive integer dry mass in kilograms and ordered steps.

  Steps may be maps or `FlightStep` structs with supported string `action` and
  `planet` fields. An empty route requires zero fuel.
  """
  @spec calculate(pos_integer(), [map()]) :: Result.t()
  def calculate(mass, steps) do
    steps
    |> Enum.reverse()
    |> Enum.reduce(%Result{}, fn step, result ->
      effective_mass = mass + result.total_fuel
      fuel = Maneuver.fuel_required(step.action, effective_mass, Planet.gravity(step.planet))
      stage = %{action: step.action, planet: step.planet, effective_mass: effective_mass, fuel: fuel}
      %Result{total_fuel: result.total_fuel + fuel, steps: [stage | result.steps]}
    end)
  end
end
