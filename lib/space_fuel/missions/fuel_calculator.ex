defmodule SpaceFuel.Missions.FuelCalculator do
  @moduledoc "Integer-only fuel calculations for validated missions."
  alias SpaceFuel.Missions.Result

  @gravity %{"earth" => 9807, "moon" => 1620, "mars" => 3711}
  @formulas %{"launch" => {42, 33}, "land" => {33, 42}}
  @scale 1_000_000

  def calculate(mass, steps) do
    steps
    |> Enum.reverse()
    |> Enum.reduce(%Result{}, fn step, result ->
      effective_mass = mass + result.total_fuel
      fuel = fuel_for(effective_mass, @gravity[step.planet], @formulas[step.action], 0)
      stage = %{action: step.action, planet: step.planet, effective_mass: effective_mass, fuel: fuel}
      %Result{total_fuel: result.total_fuel + fuel, steps: [stage | result.steps]}
    end)
  end

  defp fuel_for(mass, gravity, {coefficient, offset} = formula, total) do
    increment = div(mass * gravity * coefficient, @scale) - offset
    if increment > 0, do: fuel_for(increment, gravity, formula, total + increment), else: total
  end
end
