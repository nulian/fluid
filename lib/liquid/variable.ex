defmodule Liquid.Variable do
  @moduledoc """
    Module to create and lookup for Variables

  """
  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.{Filters, Variable, Context}

  @doc """
    resolves data from `Liquid.Variable.parse/1` and creates a variable struct
  """
  def create(markup) when is_binary(markup) do
    [name|filters] =  parse(markup)
    name = String.trim(name)
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Liquid.Appointer.parse_name(name)
    Map.merge(variable, parsed)
  end

  def create({name, filters}) do
    name = to_string(name)
    filters = filters |> parse()
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Liquid.Appointer.parse_name(name)
    Map.merge(variable, parsed)
  end

  def create(nil), do: ""

  @doc """
  Assigns context to variable and than applies all filters
  """
  def lookup(%Variable{}=v, %Context{}=context) do
    { ret, filters } = Liquid.Appointer.assign(v, context)
    try do
      filters |> Filters.filter(ret) |> apply_global_filter(context)
    rescue
      e in UndefinedFunctionError -> e.reason
      e in ArgumentError -> e.message
      e in ArithmeticError -> "Liquid error: #{e.message}"
    end
  end

  defp apply_global_filter(input, %Context{global_filter: nil}) do
    input
  end

  defp apply_global_filter(input, %Context{}=context),
   do: input |> context.global_filter.()


  @doc """
  Parses the markup to a list of filters
  """
  def parse(markup) when is_binary(markup) do
    [name|filters] = if markup != "" do
      Liquid.filter_parser
        |> Regex.scan(markup)
        |> List.flatten
        |> Enum.filter(&(&1 != "|"))
        |> Enum.map(&String.trim/1)
      else
        [""]
      end
    filters = for markup <- filters do
      [_, filter] = ~r/\s*(\w+)/ |> Regex.scan(markup) |> hd
      args = Liquid.filter_arguments
        |> Regex.scan(markup)
        |> List.flatten
        |> Liquid.List.even_elements

      [String.to_existing_atom(filter), args]
    end
    [name|filters]
  end

  def parse({filter, args}) do
    filter = :erlang.list_to_binary(filter)
    filter = try do
      String.to_existing_atom(filter)
    rescue
      ArgumentError -> filter
    end
    [filter, args]
  end

  def parse([]) do
    []
  end

  def parse([head|tail]) do
    [parse(head)|parse(tail)]
  end

end
