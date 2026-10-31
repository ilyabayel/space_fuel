defmodule SpaceFuel.Missions.Catalogs.Planet do
  @moduledoc """
  Supported planets, in display order, and their gravity values.

  Gravity is expressed in m/s² as a Decimal.
  Add a planet to `@planets` to make it available to calculation, validation,
  and form dropdowns. Callers must validate planet identifiers before lookup.
  """

  @planets [
    {"earth", "Earth", Decimal.new("9.807")},
    {"moon", "Moon", Decimal.new("1.620")},
    {"mars", "Mars", Decimal.new("3.711")}
  ]
  @options Enum.map(@planets, fn {id, label, _gravity} -> {label, id} end)
  @gravity Map.new(@planets, fn {id, _label, gravity} -> {id, gravity} end)

  @labels Map.new(@options, fn {label, id} -> {id, label} end)

  @doc "Returns the display label for a supported identifier."
  @spec get_label(String.t()) :: String.t()
  def get_label(id), do: Map.fetch!(@labels, id)

  @doc "Returns display labels and string identifiers in planet display order."
  @spec options() :: [{String.t(), String.t()}]
  def options, do: @options

  @doc "Returns gravity in m/s² for a supported planet identifier."
  @spec get_gravity(String.t()) :: Decimal.t()
  def get_gravity(planet), do: Map.fetch!(@gravity, planet)
end
