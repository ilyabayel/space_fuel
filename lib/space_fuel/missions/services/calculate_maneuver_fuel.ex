defmodule SpaceFuel.Missions.Services.CalculateManeuverFuel do
  @moduledoc "Calculates a maneuver's recursive fuel requirement using scaled integer arithmetic."

  alias SpaceFuel.Missions.Catalogs.Maneuver

  @scale 1_000_000

  @spec call(String.t(), non_neg_integer(), pos_integer()) :: non_neg_integer()
  def call(action, mass, gravity) do
    fuel_for(mass, gravity, Maneuver.formula(action), 0)
  end

  defp fuel_for(mass, gravity, {coefficient, offset} = formula, total) do
    increment = div(mass * gravity * coefficient, @scale) - offset
    if increment > 0, do: fuel_for(increment, gravity, formula, total + increment), else: total
  end
end
