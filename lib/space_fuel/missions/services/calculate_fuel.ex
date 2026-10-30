defmodule SpaceFuel.Missions.Services.CalculateFuel do
  @moduledoc """
  Accumulates fuel requirements backwards through a validated mission.

  Each stage carries the spacecraft's dry mass plus fuel for all later stages.
  Planet gravity and maneuver fuel rules are delegated to their domain modules;
  results are returned in flight order. This module is independent of Ecto and
  Phoenix and assumes callers have validated mass and step identifiers.
  """

  alias SpaceFuel.Missions.Catalogs.Planet
  alias SpaceFuel.Missions.Schemas.FlightStep
  alias SpaceFuel.Missions.Schemas.Result
  alias SpaceFuel.Missions.Services.CalculateManeuverFuel

  @type step_input ::
          %{required(:action) => String.t(), required(:planet) => String.t()} | FlightStep.t()

  @doc """
  Calculates fuel for a positive integer dry mass in kilograms and ordered steps.

  Steps may be maps or `FlightStep` structs with supported string `action` and
  `planet` fields. An empty route requires zero fuel.
  """
  @spec call(pos_integer(), [step_input()]) :: Result.t()
  def call(mass, steps) do
    steps
    |> Enum.reverse()
    |> Enum.reduce(%Result{}, fn step, result ->
      effective_mass = mass + result.total_fuel
      fuel = CalculateManeuverFuel.call(step.action, effective_mass, Planet.get_gravity(step.planet))
      stage = %{action: step.action, planet: step.planet, effective_mass: effective_mass, fuel: fuel}
      %Result{total_fuel: result.total_fuel + fuel, steps: [stage | result.steps]}
    end)
  end
end
