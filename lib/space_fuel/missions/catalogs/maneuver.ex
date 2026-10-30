defmodule SpaceFuel.Missions.Catalogs.Maneuver do
  @moduledoc """
  Supported maneuver labels and scaled formula parameters.

  Each formula is `{coefficient, offset}`. Coefficients are scaled by 1,000
  (42 represents 0.042), gravity is scaled by 1,000, and offsets are kilograms.
  The calculation service divides the product by 1,000,000 and floors each
  increment before subtracting the offset.

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

  @labels Map.new(@options, fn {label, id} -> {id, label} end)

  @doc "Returns the display label for a supported identifier."
  @spec get_label(String.t()) :: String.t()
  def get_label(id), do: Map.fetch!(@labels, id)

  @doc "Returns display labels and string identifiers in maneuver display order."
  @spec options() :: [{String.t(), String.t()}]
  def options, do: @options

  @doc "Returns the scaled formula for a supported maneuver."
  def get_formula(action), do: Map.fetch!(@formulas, action)
end
