defprotocol Liquid.Matcher do
  @fallback_to_any true
  @doc "Assigns context to values"
  def match(_, _, _)
end

defimpl Liquid.Matcher, for: Liquid.Context do
  @doc """
  `Liquid.Matcher` protocol implementation for `Liquid.Context`
  """

  def match(current, [], _full_context), do: current

  def match(%{assigns: assigns, presets: presets}, [key | _] = parts, full_context)
      when is_binary(key) do
    current =
      cond do
        assigns |> Map.has_key?(key) -> assigns
        presets |> Map.has_key?(key) -> presets
        !is_nil(Map.get(assigns, key |> Liquid.Atomizer.to_existing_atom())) -> assigns
        !is_nil(Map.get(presets, key |> Liquid.Atomizer.to_existing_atom())) -> presets
        is_map(assigns) and Map.has_key?(assigns, :__struct__) -> assigns
        true -> nil
      end

    Liquid.Matcher.match(current, parts, full_context)
  end
end

defimpl Liquid.Matcher, for: Map do
  def match(current, [], _full_context), do: current

  def match(current, ["size" | _], _full_context), do: current |> map_size

  def match(current, [<<?[, index::binary>> | parts], full_context) do
    index = index |> String.split("]") |> hd |> String.replace(Liquid.Parse.quote_matcher(), "")
    match(current, [index | parts], full_context)
  end

  def match(current, [name | parts], full_context) when is_binary(name) do
    current |> Liquid.Matcher.match(name, full_context) |> Liquid.Matcher.match(parts, full_context)
  end

  def match(current, key, _full_context) when is_binary(key), do: current[key]
end

defimpl Liquid.Matcher, for: List do
  def match(current, [], _full_context), do: current

  def match(current, ["size" | _], _full_context), do: current |> Enum.count()

  def match(current, ["length" | _], _full_context), do: current |> Enum.count()

  def match(current, [<<?[, index::binary>> | parts], full_context) do
    index = index |> String.split("]") |> hd |> String.to_integer()

    current
    |> Enum.fetch(index)
    |> case do
      :error -> nil
      {:ok, val} -> val |> Liquid.Matcher.match(parts, full_context)
    end
  end
end

defimpl Liquid.Matcher, for: Any do
  def match(nil, _, _full_context), do: nil

  def match(current, [], _full_context), do: current

  def match(true, _, _full_context), do: nil

  @doc """
  Match size for strings:
  """
  def match(current, ["size" | _], _full_context) when is_binary(current), do: current |> String.length()

  @doc """
  Match functions for structs:
  """
  def match(current, [name | parts], full_context) when is_map(current) and is_binary(name) do
    current |> Liquid.Matcher.match(name, full_context) |> Liquid.Matcher.match(parts, full_context)
  end

  def match(current, key, _full_context) when is_map(current) and is_binary(key) do
    key =
      if Map.has_key?(current, :__struct__),
        do: key |> Liquid.Atomizer.to_existing_atom(),
        else: key

    current |> Map.get(key)
  end

  def match(val, ["is_nil"], _full_context) when is_nil(val), do: true
  def match(val, ["is_nil"], _full_context) when not is_nil(val), do: false

  @doc """
  Matches all remaining cases
  """
  # !is_list(current)
  def match(_current, key, _full_context) when is_binary(key), do: nil
end
