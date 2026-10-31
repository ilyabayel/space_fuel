defmodule SpaceFuel.Missions.Catalogs.Maneuver do
  @moduledoc """
  Supported maneuver labels and formula parameters.

  Each formula is `{coefficient, offset}`. Coefficients are Decimals, and
  offsets are kilograms. Each fuel increment is rounded down to whole kilograms.

  Add a formula to `@maneuvers` to expose it to calculation, validation, and
  form dropdowns. Supported planet/formula combinations must produce shrinking
  increments so recursion terminates. Callers must supply a validated action,
  nonnegative integer mass in kilograms, and supported gravity.
  """

  @maneuvers [
    {"launch", "Launch", {Decimal.new("0.042"), 33}},
    {"land", "Land", {Decimal.new("0.033"), 42}}
  ]
  @options Enum.map(@maneuvers, fn {id, label, _formula} -> {label, id} end)
  @formulas Map.new(@maneuvers, fn {id, _label, formula} -> {id, formula} end)

  @labels Map.new(@options, fn {label, id} -> {id, label} end)

  @doc "Returns the display label for a supported identifier."
  @spec get_label(String.t()) :: String.t()
  def get_label(id), do: Map.fetch!(@labels, id)

  @doc "Returns display labels and string identifiers in maneuver display order."
  @spec options() :: [{String.t(), String.t()}]
  def options, do: @options

  @doc "Returns the formula for a supported maneuver."
  def get_formula(action), do: Map.fetch!(@formulas, action)
end
