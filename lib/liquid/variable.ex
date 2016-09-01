defmodule Liquid.Variable do
  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.Filters, as: Filters
  alias Liquid.Variable, as: Variable
  alias Liquid.Variable, as: Variable
  alias Liquid.Context, as: Context

  defp literals, do: %{"nil" => nil, "null" => nil, "" => nil,
                      "true" => true, "false" => false,
                      "blank" => :blank?, "empty" => :empty?}

  def integer, do: ~r/^(-?\d+)$/
  def float, do: ~r/^(-?\d[\d\.]+)$/
  def quoted_string, do: ~r/#{Liquid.quoted_string}/

  @doc """
    matches for [] access
  """
  def create(markup) when is_binary(markup) do
    [name|filters] = Filters.parse(markup)
    key = name |> String.strip
    variable = %Liquid.Variable{name: name, filters: filters}
    cond do
      literals      |> Map.has_key?(key) ->
        value = literals |> Map.get(key)
        %{variable | literal: value }
      integer       |> Regex.match?(name) ->
        value = name |> String.to_integer
        %{variable | literal: value }
      float         |> Regex.match?(name) ->
        value = name |> String.to_float
        %{variable | literal: value }
      quoted_string |> Regex.match?(name) ->
        unquoted_name = Liquid.quote_matcher |> Regex.replace(name, "")
        %{ variable | literal: unquoted_name }
      true ->
        [name|_] = String.split(name, " ")
        parts = Regex.scan(Liquid.variable_parser, name) |> List.flatten
        %{variable | parts: parts}
    end
  end

  def lookup(%Variable{filters: filters}=v, %Context{}=context) do
    { ret, context } = case v do
      %Variable{literal: literal, parts: []} ->
        { literal, context }
      %Variable{literal: nil, parts: parts} ->
        resolve(parts, context, context)
    end
    ret = Filters.filter(filters, ret, context)
    { ret, context }
  end

  defp resolve([<<key::binary>>|_]=parts, %Context{}=current, %Context{}=context) do
    cond do
      current.assigns |> Map.has_key?(key) ->
        resolve(parts, current.assigns, context)
      current.presets |> Map.has_key?(key) ->
        resolve(parts, current.presets, context)
      true -> { nil, context }
    end
  end
  defp resolve([], current, %Context{}=context), do: { current, context }
  defp resolve([<<?[,index::binary>>|parts], current, %Context{}=context) do
    [index, _] = String.split(index, "]")
    index = String.to_integer(index)
    resolve(parts, current |> Enum.fetch!(index), context)
  end

  defp resolve(["size"|_], current, %Context{}=context) when is_list(current) do
    { current |> Enum.count, context }
  end

  defp resolve(["size"|_], current, %Context{}=context) when is_map(current) do
    { current |> map_size, context }
  end

  defp resolve([name|parts], current, %Context{}=context) when is_binary(name) do
    { current, context } = resolve(name, current, context)
    resolve(parts, current, context)
  end
  defp resolve(<<_::binary>>, current, %Context{}=context) when not is_map(current), do: { nil, context } # !is_list(current)
  defp resolve(key, current, %Context{}=context) when is_map(current) and is_binary(key) do
    return = current[key]
    { return, context }
  end
end
