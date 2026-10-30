defmodule SpaceFuel.Missions.Maneuver do
  @moduledoc """
  Supported maneuvers and their recursive, integer-only fuel calculations.

  Each formula is `{coefficient, offset}`. Coefficients are scaled by 1,000
  (42 represents 0.042), gravity is scaled by 1,000, and offsets are kilograms.
  Dividing the product by 1,000,000 floors each fuel increment before the offset
  is subtracted. Positive increments also need fuel; recursion stops when the
  next increment is nonpositive.

  Add a formula to `@maneuvers` to expose it to calculation, validation, and
  form dropdowns. Supported planet/formula combinations must produce shrinking
  increments so recursion terminates. Callers must supply a validated action,
  nonnegative integer mass in kilograms, and supported scaled gravity.
  """

  @maneuvers [
    {"launch", "Launch", {42, 33}},
    {"land", "Land", {33, 42}}
  ]
  @options Enum.map(@maneuvers, fn {id, label, _formula} -> {label, id} end)
  @formulas Map.new(@maneuvers, fn {id, _label, formula} -> {id, formula} end)
  @scale 1_000_000

  @labels Map.new(@options, fn {label, id} -> {id, label} end)

  @doc "Returns the display label for a supported identifier."
  @spec label(String.t()) :: String.t()
  def label(id), do: Map.fetch!(@labels, id)

  @doc "Returns display labels and string identifiers in maneuver display order."
  @spec options() :: [{String.t(), String.t()}]
  def options, do: @options

  @doc "Returns fuel in kilograms, including the fuel needed to carry fuel."
  @spec fuel_required(String.t(), non_neg_integer(), pos_integer()) :: non_neg_integer()
  def fuel_required(action, mass, gravity) do
    fuel_for(mass, gravity, Map.fetch!(@formulas, action), 0)
  end

  defp fuel_for(mass, gravity, {coefficient, offset} = formula, total) do
    increment = div(mass * gravity * coefficient, @scale) - offset
    if increment > 0, do: fuel_for(increment, gravity, formula, total + increment), else: total
  end
end
