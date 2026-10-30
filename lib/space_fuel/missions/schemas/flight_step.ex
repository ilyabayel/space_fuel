defmodule SpaceFuel.Missions.Schemas.FlightStep do
  @moduledoc "An embedded flight stage with a generated UUID and catalog identifiers."
  use Ecto.Schema

  import Ecto.Changeset

  alias SpaceFuel.Missions.Catalogs.Maneuver
  alias SpaceFuel.Missions.Catalogs.Planet

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:action, :string)
    field(:planet, :string)
  end

  @type t :: %__MODULE__{}

  @doc "Validates stage attributes and generates an ID when one is absent."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(step, attrs) do
    step
    |> cast(attrs, [:id, :action, :planet])
    |> ensure_id()
    |> validate_required([:action, :planet])
    |> validate_inclusion(:action, Enum.map(Maneuver.options(), &elem(&1, 1)))
    |> validate_inclusion(:planet, Enum.map(Planet.options(), &elem(&1, 1)))
  end

  defp ensure_id(changeset) do
    if get_field(changeset, :id), do: changeset, else: put_change(changeset, :id, Ecto.UUID.generate())
  end
end
