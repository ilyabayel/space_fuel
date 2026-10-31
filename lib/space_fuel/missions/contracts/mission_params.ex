defmodule SpaceFuel.Missions.Contracts.MissionParams do
  @moduledoc "Checks raw mission input shape and resource limits before Ecto casting."

  @max_steps 50
  @max_mass 999_999_999_999
  @max_scalar_bytes 64
  @mission_fields [
    mass: "mass",
    steps: "steps",
    steps_sort: "steps_sort",
    steps_drop: "steps_drop",
    _unused_mass: "_unused_mass"
  ]
  @step_fields [
    id: "id",
    action: "action",
    planet: "planet",
    _unused_id: "_unused_id",
    _unused_action: "_unused_action",
    _unused_planet: "_unused_planet"
  ]

  @doc "Maximum number of flight stages accepted by the planner."
  @spec max_steps() :: pos_integer()
  def max_steps, do: @max_steps

  @doc "Maximum spacecraft mass accepted by the planner, in kilograms."
  @spec max_mass() :: pos_integer()
  def max_mass, do: @max_mass

  @doc "Returns safe parameters or a field and rejection message. Bound and normalize raw input before Ecto expands and casts embedded rows."
  @spec validate(term()) :: {:ok, map()} | {:error, {atom(), String.t()}}
  def validate(params) when is_map(params) and not is_struct(params) do
    params = get_known_fields(params, @mission_fields)

    with :ok <- validate_mass(Map.get(params, :mass)),
         {:ok, steps} <- validate_steps(Map.get(params, :steps, %{})),
         {:ok, sort} <- validate_indexes(Map.get(params, :steps_sort, []), @max_steps),
         {:ok, drop} <- validate_drop(Map.get(params, :steps_drop, [])),
         :ok <- validate_step_count(steps, sort, drop),
         :ok <- validate_ids(steps),
         :ok <- validate_unused(params) do
      {:ok, safe_params(params, steps)}
    end
  end

  def validate(_), do: {:error, {:steps, "Mission input is malformed."}}

  defp safe_params(params, steps) do
    params
    |> Map.take([:mass, :steps_sort, :steps_drop, :_unused_mass])
    |> put_steps_if_present(params, steps)
  end

  defp put_steps_if_present(safe, %{steps: _}, steps), do: Map.put(safe, :steps, steps)
  defp put_steps_if_present(safe, _params, _steps), do: safe

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
    Enum.reduce_while(steps, {:ok, %{}}, fn entry, {:ok, safe} ->
      case normalize_step_entry(entry) do
        {:ok, {index, step}} -> {:cont, {:ok, Map.put(safe, index, step)}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp validate_steps(steps) when is_list(steps) or is_map(steps),
    do: {:error, {:steps, "A route can contain at most 50 flight stages."}}

  defp validate_steps(_), do: {:error, {:steps, "Flight stages must be a collection of stages."}}

  defp normalize_step_entry({index, step}) do
    with :ok <- validate_step_index(index),
         {:ok, step} <- normalize_step(step) do
      {:ok, {index, step}}
    end
  end

  defp validate_step_index(index) do
    if accepts_index?(index) do
      :ok
    else
      {:error, {:steps, "Flight stages contain malformed values."}}
    end
  end

  defp normalize_step(step) when is_map(step) and not is_struct(step) do
    step = get_known_fields(step, @step_fields)

    if Enum.all?(Map.values(step), &accepts_scalar?(&1, @max_scalar_bytes)) do
      {:ok, step}
    else
      {:error, {:steps, "Flight stages contain malformed values."}}
    end
  end

  defp normalize_step(_), do: {:error, {:steps, "Flight stages contain malformed values."}}

  defp validate_unused(params) do
    if accepts_scalar?(Map.get(params, :_unused_mass), @max_scalar_bytes) do
      :ok
    else
      {:error, {:mass, "Mass input is malformed."}}
    end
  end

  defp validate_indexes(indexes, limit) when is_list(indexes) do
    if length(indexes) <= limit and Enum.all?(indexes, &accepts_index?/1) do
      {:ok, indexes}
    else
      {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  defp validate_indexes(_, _), do: {:error, {:steps, "Flight stage ordering or removal is malformed."}}

  defp validate_drop(drop) when is_list(drop) do
    with {:ok, indexes} <- validate_indexes(drop, @max_steps + 1),
         :ok <- validate_drop_count(indexes) do
      {:ok, indexes}
    end
  end

  defp validate_drop(_), do: {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}

  defp validate_drop_count(indexes) do
    if Enum.count(indexes, &(&1 == "")) <= 1 and
         Enum.count(indexes, &(&1 != "")) <= @max_steps do
      :ok
    else
      {:error, {:steps, "Flight stage ordering or removal is invalid or too large."}}
    end
  end

  defp accepts_index?(index), do: is_binary(index) and byte_size(index) <= @max_scalar_bytes
  defp accepts_scalar?(nil, _limit), do: true
  defp accepts_scalar?(value, limit), do: is_binary(value) and byte_size(value) <= limit

  defp validate_step_count(steps, sort, drop) do
    sorted = sort -- drop
    pending = Map.drop(steps, sorted ++ drop)

    if length(sorted) + map_size(pending) <= @max_steps do
      :ok
    else
      {:error, {:steps, "A route can contain at most 50 flight stages."}}
    end
  end

  defp validate_ids(steps) do
    ids = steps |> Map.values() |> Enum.map(&Map.get(&1, :id)) |> Enum.reject(&(&1 in [nil, ""]))

    if Enum.all?(ids, &(byte_size(&1) == 36 and match?({:ok, _}, Ecto.UUID.cast(&1)))) and
         length(ids) == length(Enum.uniq_by(ids, &String.downcase/1)) do
      :ok
    else
      {:error, {:steps, "Flight stage identifiers are invalid or duplicated."}}
    end
  end

  # Field atoms are fixed at compile time; form submissions use the corresponding string keys.
  defp get_known_fields(params, fields) do
    Enum.reduce(fields, %{}, fn {atom_key, string_key}, result ->
      case fetch_field(params, atom_key, string_key) do
        {:ok, value} -> Map.put(result, atom_key, value)
        :error -> result
      end
    end)
  end

  defp fetch_field(params, atom_key, string_key) do
    case Map.fetch(params, atom_key) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(params, string_key)
    end
  end
end
