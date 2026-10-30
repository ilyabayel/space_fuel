defmodule SpaceFuel.Missions.Schemas.Mission do
  @moduledoc "An embedded mission and its ordered flight stages."
  use Ecto.Schema

  import Ecto.Changeset

  alias SpaceFuel.Missions.Contracts.MissionParams
  alias SpaceFuel.Missions.Schemas.FlightStep

  embedded_schema do
    field(:mass, :integer)
    embeds_many(:steps, FlightStep, on_replace: :delete)
  end

  @type t :: %__MODULE__{}

  @doc "Validates external parameters and casts ordered flight stages."
  @spec changeset(t(), term()) :: Ecto.Changeset.t()
  def changeset(mission, attrs) do
    case MissionParams.validate(attrs) do
      {:ok, params} ->
        mission
        |> cast(params, [:mass])
        |> validate_required([:mass])
        |> validate_number(:mass, greater_than: 0, less_than_or_equal_to: MissionParams.max_mass())
        |> cast_embed(:steps, with: &build_step_changeset/2, sort_param: :steps_sort, drop_param: :steps_drop)
        |> validate_length(:steps, max: MissionParams.max_steps())

      {:error, {field, message}} ->
        mission
        |> change()
        |> add_error(field, message, validation: :input_boundary)
    end
  end

  @doc "Returns the boundary rejection message when raw input cannot be safely rendered."
  @spec get_input_error(Ecto.Changeset.t()) :: String.t() | nil
  def get_input_error(%Ecto.Changeset{errors: errors}) do
    Enum.find_value(errors, fn {_field, {message, opts}} ->
      if opts[:validation] == :input_boundary, do: message
    end)
  end

  defp build_step_changeset(step, attrs) do
    attrs = if attrs == %{}, do: %{"action" => "launch", "planet" => "earth"}, else: attrs
    FlightStep.changeset(step, attrs)
  end
end
