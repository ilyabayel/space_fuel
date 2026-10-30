defmodule SpaceFuel.Missions.FlightStep do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:action, :string)
    field(:planet, :string)
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:id, :action, :planet])
    |> ensure_id()
    |> validate_required([:action, :planet])
    |> validate_inclusion(:action, ~w(launch land))
    |> validate_inclusion(:planet, ~w(earth moon mars))
  end

  defp ensure_id(changeset) do
    if get_field(changeset, :id), do: changeset, else: put_change(changeset, :id, Ecto.UUID.generate())
  end
end
