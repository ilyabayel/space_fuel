defmodule SpaceFuel.Missions.Schemas.Result do
  @moduledoc "The total fuel and stages in flight order."
  defstruct total_fuel: 0, steps: []

  @type stage :: %{
          action: String.t(),
          planet: String.t(),
          effective_mass: pos_integer(),
          fuel: non_neg_integer()
        }
  @type t :: %__MODULE__{total_fuel: non_neg_integer(), steps: [stage()]}
end
