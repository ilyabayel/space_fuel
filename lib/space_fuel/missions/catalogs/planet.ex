defmodule SpaceFuel.Missions.Catalogs.Planet do
  @moduledoc """
  Supported planets, in display order, and their gravity values.

  Gravity is expressed in m/s² scaled by 1,000 (Earth's 9.807 becomes 9,807).
  Add a planet to `@planets` to make it available to calculation, validation,
  and form dropdowns. Callers must validate planet identifiers before lookup.
  """

  @planets [
    {"earth", "Earth", 9807},
    {"moon", "Moon", 1620},
    {"mars", "Mars", 3711}
  ]
  @options Enum.map(@planets, fn {id, label, _gravity} -> {label, id} end)
  @gravity Map.new(@planets, fn {id, _label, gravity} -> {id, gravity} end)

  @labels Map.new(@options, fn {label, id} -> {id, label} end)

  @doc "Returns the display label for a supported identifier."
  @spec label(String.t()) :: String.t()
  def label(id), do: Map.fetch!(@labels, id)

  @doc "Returns display labels and string identifiers in planet display order."
  @spec options() :: [{String.t(), String.t()}]
  def options, do: @options

  @doc "Returns gravity scaled by 1,000 for a supported planet identifier."
  @spec gravity(String.t()) :: pos_integer()
  def gravity(planet), do: Map.fetch!(@gravity, planet)
end
