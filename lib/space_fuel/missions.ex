defmodule SpaceFuel.Missions do
  @moduledoc "Public API for mission validation, reference data, and fuel calculations."

  alias SpaceFuel.Missions.Catalogs.Maneuver
  alias SpaceFuel.Missions.Catalogs.Planet
  alias SpaceFuel.Missions.Catalogs.Presets
  alias SpaceFuel.Missions.Contracts.MissionParams
  alias SpaceFuel.Missions.Schemas.Mission
  alias SpaceFuel.Missions.Schemas.Result
  alias SpaceFuel.Missions.Services.CalculateFuel
  alias SpaceFuel.Missions.Services.CalculateManeuverFuel

  @doc "Returns a changeset for external mission input."
  @spec change_mission(term()) :: Ecto.Changeset.t()
  def change_mission(attrs), do: Mission.changeset(%Mission{}, attrs)

  @doc "Returns a message when input was rejected before casting."
  @spec get_input_error(Ecto.Changeset.t()) :: String.t() | nil
  defdelegate get_input_error(changeset), to: Mission

  @doc "Calculates a mission from a valid changeset."
  @spec calculate_mission(Ecto.Changeset.t()) :: Result.t()
  def calculate_mission(%Ecto.Changeset{valid?: true} = changeset) do
    mission = Ecto.Changeset.apply_changes(changeset)
    calculate_fuel(mission.mass, mission.steps)
  end

  @doc "Calculates fuel for a validated mass and ordered route."
  @spec calculate_fuel(pos_integer(), [CalculateFuel.step_input()]) :: Result.t()
  defdelegate calculate_fuel(mass, steps), to: CalculateFuel, as: :call

  @doc "Returns maneuver fuel for a validated action, mass and scaled gravity."
  @spec calculate_maneuver_fuel(String.t(), non_neg_integer(), pos_integer()) :: non_neg_integer()
  defdelegate calculate_maneuver_fuel(action, mass, gravity), to: CalculateManeuverFuel, as: :call

  @doc "Maximum accepted spacecraft mass in kilograms."
  defdelegate max_mass(), to: MissionParams
  @doc "Maximum accepted route length."
  defdelegate max_steps(), to: MissionParams
  @doc "Ordered maneuver labels and identifiers."
  defdelegate maneuver_options(), to: Maneuver, as: :options
  @doc "Display label for a validated maneuver identifier."
  defdelegate get_maneuver_label(id), to: Maneuver, as: :get_label
  @doc "Ordered planet labels and identifiers."
  defdelegate planet_options(), to: Planet, as: :options
  @doc "Display label for a validated planet identifier."
  defdelegate get_planet_label(id), to: Planet, as: :get_label
  @doc "Gravity for a validated planet identifier, scaled by 1,000."
  defdelegate get_gravity(id), to: Planet
  @doc "Ordered reference missions and picker metadata."
  defdelegate presets(), to: Presets, as: :presets
  @doc "Returns a reference mission by identifier, or nil."
  defdelegate get_preset(id), to: Presets, as: :get
  @doc "Describes the planet sequence of a reference mission."
  defdelegate get_preset_route_description(preset), to: Presets, as: :get_route_description
end
