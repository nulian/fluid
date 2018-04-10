defmodule Liquid.Variable do
  @moduledoc """
  Module to create and lookup for Variables
  """

  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.{Appointer, Filters, Variable, Context}

  @doc """
  Resolves data from `Liquid.Variable.parse/1` and creates a variable struct
  """
  @spec create(markup :: String.t()) :: %{}
  def create(markup) when is_binary(markup) do
    [name | filters] = markup |> parse()
    name = String.trim(name)
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Appointer.parse_name(name)
    Map.merge(variable, parsed)
  end

  @doc """
  Assigns context to variable and than applies all filters
  """
  @spec lookup(v :: %Liquid.Variable{}, context :: %Liquid.Context{}) ::
          {String.t(), %Liquid.Context{}}
  def lookup(%Variable{} = v, %Context{} = context) do
    {ret, filters} = Appointer.assign(v, context)

    result =
      try do
        {:ok, filters |> Filters.filter(ret) |> apply_global_filter(context)}
      rescue
        e in UndefinedFunctionError -> {e, e.reason}
        e in ArgumentError -> {e, e.message}
        e in ArithmeticError -> {e, "Liquid error: #{e.message}"}
      end

    case result do
      {:ok, text} -> {text, context}
      {error, message} -> process_error(context, error, message)
    end
  end

  defp process_error(%Context{template: template} = context, error, message) do
    error_mode = Application.get_env(:liquid, :error_mode, :lax)

    case error_mode do
      :lax ->
        {message, context}

      :strict ->
        context = %{context | template: %{template | errors: template.errors ++ [error]}}
        {nil, context}
    end
  end

  defp apply_global_filter(input, %Context{global_filter: nil}), do: input

  defp apply_global_filter(input, %Context{global_filter: global_filter}),
    do: global_filter.(input)

  @doc """
  Parses the markup to a list of filters
  """
  @spec parse(markup :: String.t()) :: []
  def parse(markup) when is_binary(markup) do
    parsed_variable =
      if markup != "" do
        Liquid.filter_parser()
        |> Regex.scan(markup)
        |> List.flatten()
        |> Enum.map(&String.trim/1)
      else
        [""]
      end

    if hd(parsed_variable) == "|" or hd(Enum.reverse(parsed_variable)) == "|" do
      raise Liquid.SyntaxError, message: "You cannot use an empty filter"
    end

    [name | filters] = Enum.filter(parsed_variable, &(&1 != "|"))

    filters = parse_filters(filters)
    [name | filters]
  end

  defp parse_filters(filters) do
    for markup <- filters do
      [_, filter] = ~r/\s*(\w+)/ |> Regex.scan(markup) |> hd()

      args =
        Liquid.filter_arguments()
        |> Regex.scan(markup)
        |> List.flatten()
        |> Liquid.List.even_elements()

      [String.to_atom(filter), args]
    end
  end
end
