defmodule SpaceFuel.Missions.Mission do
  @moduledoc "Validates mission parameters and their ordered embedded flight stages."
  use Ecto.Schema

  import Ecto.Changeset

  alias SpaceFuel.Missions.FlightStep

  @max_steps 50
  @max_mass 999_999_999_999
  @max_scalar_bytes 64

  embedded_schema do
    field(:mass, :integer)
    embeds_many(:steps, FlightStep, on_replace: :delete)
  end

  @doc "Maximum number of flight stages accepted by the planner."
  @spec max_steps() :: pos_integer()
  def max_steps, do: @max_steps

  @doc "Maximum spacecraft mass accepted by the planner, in kilograms."
  @spec max_mass() :: pos_integer()
  def max_mass, do: @max_mass

  @doc "Validates external params, including Ecto sort/drop controls; empty new rows default to an Earth launch."
  @spec changeset(t(), term()) :: Ecto.Changeset.t()
  def changeset(mission, attrs) do
    case prepare_params(attrs) do
      {:ok, params} ->
        mission
        |> cast(params, [:mass])
        |> validate_required([:mass])
        |> validate_number(:mass, greater_than: 0, less_than_or_equal_to: @max_mass)
        |> cast_embed(:steps, with: &step_changeset/2, sort_param: :steps_sort, drop_param: :steps_drop)
        |> validate_length(:steps, max: @max_steps)

      {:error, {field, message}} ->
        mission |> change() |> add_error(field, message, validation: :input_boundary)
    end
  end

  @type t :: %__MODULE__{}

  @doc "Returns the boundary rejection message when raw input cannot be safely rendered."
  @spec input_error(Ecto.Changeset.t()) :: String.t() | nil
  def input_error(%Ecto.Changeset{errors: errors}) do
    Enum.find_value(errors, fn {_field, {message, opts}} ->
      if opts[:validation] == :input_boundary, do: message
    end)
  end

  defp step_changeset(step, attrs) do
    attrs = if attrs == %{}, do: %{"action" => "launch", "planet" => "earth"}, else: attrs
    FlightStep.changeset(step, attrs)
  end

  # Bound and normalize raw input before Ecto expands and casts embedded rows.
  defp prepare_params(params) when is_map(params) and not is_struct(params) do
    params = stringify_keys(params)

    with :ok <- validate_mass(Map.get(params, "mass")),
         {:ok, steps} <- validate_steps(Map.get(params, "steps", %{})),
         {:ok, sort} <- validate_indexes(Map.get(params, "steps_sort", []), @max_steps),
         {:ok, drop} <- validate_drop(Map.get(params, "steps_drop", [])),
         :ok <- validate_step_count(steps, sort, drop),
         :ok <- validate_ids(steps),
         :ok <- validate_unused(params) do
      safe = Map.take(params, ["mass", "steps_sort", "steps_drop", "_unused_mass"])
      safe = if Map.has_key?(params, "steps"), do: Map.put(safe, "steps", steps), else: safe
      {:ok, safe}
    end
  end

  defp prepare_params(_), do: {:error, {:steps, "Mission input is malformed."}}

  defp validate_mass(value) when is_binary(value) and byte_size(value) <= 12, do: :ok
  defp validate_mass(value) when is_integer(value) and value >= -@max_mass and value <= @max_mass, do: :ok
  defp validate_mass(nil), do: :ok

  defp validate_mass(value) when is_binary(value) or is_integer(value),
    do: {:error, {:mass, "Mass must contain at most 12 digits."}}

  defp validate_mass(_), do: {:error, {:mass, "Mass input is malformed."}}

  defp validate_steps(steps) when is_list(steps) and length(steps) <= @max_steps do
    steps
    |> Enum.with_index()
    |> Map.new(fn {step, index} -> {Integer.to_string(index), step} end)
    |> validate_steps()
  end

  defp validate_steps(steps) when is_map(steps) and not is_struct(steps) and map_size(steps) <= @max_steps do
    if Enum.all?(steps, fn {index, step} -> valid_index?(index) and valid_step?(step) end) do
      {:ok,
       Map.new(steps, fn {index, step} ->
         {index,
          step
          |> stringify_keys()
          |> Map.take(["id", "action", "planet", "_unused_id", "_unused_action", "_unused_planet"])}
       end)}
    else
      {:error, {:steps, "Flight stages contain malformed values."}}
    end
  end

  defp validate_steps(steps) when is_list(steps) or is_map(steps),
    do: {:error, {:steps, "A route can contain at most 50 flight stages."}}

  defp validate_steps(_), do: {:error, {:steps, "Flight stages must be a collection of stages."}}

  defp valid_step?(step) when is_map(step) and not is_struct(step) do
    step = stringify_keys(step)

    Enum.all?(["action", "planet", "id", "_unused_action", "_unused_planet", "_unused_id"], fn key ->
      scalar?(Map.get(step, key), @max_scalar_bytes)
    end)
  end

  defp valid_step?(_), do: false

  defp validate_unused(params) do
    if scalar?(Map.get(params, "_unused_mass"), @max_scalar_bytes),
      do: :ok,
      else: {:error, {:mass, "Mass input is malformed."}}
  end

  defp validate_indexes(indexes, limit) when is_list(indexes) do
    if length(indexes) <= limit and Enum.all?(indexes, &valid_index?/1) do
      {:ok, indexes}
    else
      {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  defp validate_indexes(_, _), do: {:error, {:steps, "Flight stage ordering or removal is malformed."}}

  defp validate_drop(drop) do
    with {:ok, indexes} <- validate_indexes(drop, @max_steps + 1),
         true <- Enum.count(indexes, &(&1 == "")) <= 1,
         true <- Enum.count(indexes, &(&1 != "")) <= @max_steps do
      {:ok, indexes}
    else
      _ -> {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  defp valid_index?(index), do: is_binary(index) and byte_size(index) <= @max_scalar_bytes
  defp scalar?(nil, _limit), do: true
  defp scalar?(value, limit), do: is_binary(value) and byte_size(value) <= limit

  defp validate_step_count(steps, sort, drop) do
    sorted = sort -- drop
    pending = Map.drop(steps, sorted ++ drop)

    if length(sorted) + map_size(pending) <= @max_steps,
      do: :ok,
      else: {:error, {:steps, "A route can contain at most 50 flight stages."}}
  end

  defp validate_ids(steps) do
    ids = steps |> Map.values() |> Enum.map(&Map.get(&1, "id")) |> Enum.reject(&(&1 in [nil, ""]))

    if Enum.all?(ids, &(byte_size(&1) == 36 and match?({:ok, _}, Ecto.UUID.cast(&1)))) and
         length(ids) == length(Enum.uniq_by(ids, &String.downcase/1)) do
      :ok
    else
      {:error, {:steps, "Flight stage identifiers are invalid or duplicated."}}
    end
  end

  defp stringify_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      pair -> pair
    end)
  end
end
