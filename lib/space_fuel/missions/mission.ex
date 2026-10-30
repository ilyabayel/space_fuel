defmodule SpaceFuel.Missions.Mission do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias SpaceFuel.Missions.FlightStep

  embedded_schema do
    field(:mass, :integer)
    embeds_many(:steps, FlightStep, on_replace: :delete)
  end

  def changeset(mission, attrs) do
    mission
    |> cast(attrs, [:mass])
    |> validate_required([:mass])
    |> validate_number(:mass, greater_than: 0)
    |> cast_embed(:steps, with: &step_changeset/2, sort_param: :steps_sort, drop_param: :steps_drop)
  end

  defp step_changeset(step, attrs) do
    attrs = if attrs == %{}, do: %{"action" => "launch", "planet" => "earth"}, else: attrs
    FlightStep.changeset(step, attrs)
  end
end
