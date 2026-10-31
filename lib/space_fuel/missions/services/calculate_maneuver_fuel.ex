defmodule SpaceFuel.Missions.Services.CalculateManeuverFuel do
  @moduledoc "Calculates a maneuver's recursive fuel requirement using exact decimal arithmetic."

  alias SpaceFuel.Missions.Catalogs.Maneuver

  @spec call(String.t(), non_neg_integer(), Decimal.t()) :: non_neg_integer()
  def call(action, mass, gravity) do
    {coefficient, _offset} = formula = Maneuver.get_formula(action)
    # Keep every digit of the product before rounding to whole kilograms.
    precision = max(34, digits(mass) + digits(gravity.coef) + digits(coefficient.coef))
    context = %Decimal.Context{precision: precision}

    Decimal.Context.with(context, fn ->
      calculate_fuel(mass, gravity, formula, 0)
    end)
  end

  defp digits(integer), do: byte_size(Integer.to_string(integer))

  defp calculate_fuel(mass, gravity, {coefficient, offset} = formula, total) do
    increment =
      mass
      |> Decimal.mult(gravity)
      |> Decimal.mult(coefficient)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
      |> Kernel.-(offset)

    if increment > 0 do
      calculate_fuel(increment, gravity, formula, total + increment)
    else
      total
    end
  end
end
