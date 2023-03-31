defmodule Liquid.Variable do
  @moduledoc """
    Module to create and lookup for Variables

  """
  # , file: nil, line: nil
  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.{Appointer, Filters, Variable, Context}

  @doc """
    resolves data from `Liquid.Variable.parse/1` and creates a variable struct
  """
  def create(markup) when is_binary(markup) do
    [name | filters] = markup |> parse
    name = String.trim(name)
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Liquid.Appointer.parse_name(name)

    if String.contains?(name, "%") do
      raise Liquid.SyntaxError, message: "Invalid variable name"
    end

    Map.merge(variable, parsed)
  end

  @doc """
  Assigns context to variable and than applies all filters
  """
  @spec lookup(%Variable{}, %Context{}, Keyword.t()) :: {String.t() | nil, %Context{}}
  def lookup(%Variable{} = v, %Context{} = context, options) do
    {ret, filters} = Appointer.assign(v, context)

    filename = extract_filename_from_context(context)

    result =
      try do
        {:ok, filters |> Filters.filter(context, ret, options) |> apply_global_filter(context)}
      rescue
        e in UndefinedFunctionError ->
          {e, "variable: #{v.name}, error: #{e.reason}"}

        e in ArgumentError ->
          {e, "variable: #{v.name}, error: #{e.message}"}

        e in ArithmeticError ->
          {e, "variable: #{v.name}, Liquid error: #{e.message}, filename: #{filename}"}
      end


    case result do
      {:ok, {:safe, text}} -> {text, context}
      {:ok, text} when is_binary(text) -> {HtmlSanitizeEx.basic_html(text), context}
      {:ok, text} -> {text, context}
      {error, message} -> process_error(context, error, message, options)
    end
  end

  defp extract_filename_from_context(%{template: %{filename: filename}}), do: filename
  defp extract_filename_from_context(_), do: :root

  defp process_error(%Context{template: template} = context, error, message, options) do
    error_mode = Keyword.get(options, :error_mode, :lax)

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
  def parse(markup) when is_binary(markup) do
    parsed_variable =
      if markup != "" do
        Liquid.Parse.filter_parser()
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
        Liquid.Parse.filter_arguments()
        |> Regex.scan(markup)
        |> Enum.map(fn item ->
          case item do
            [_, key, val] -> {key, val}
            [_, val] -> val
          end
        end)
        |> Enum.split_with(&is_tuple/1)
        |> (fn {tuples, values} ->
              tuples
              |> Enum.reduce(%{__mapdata__: "true"}, fn {key, val}, acc ->
                acc |> Map.put(key, val)
              end)
              |> case do
                %{__mapdata__: _} = data when map_size(data) == 1 -> values
                data -> values ++ [data]
              end
            end).()

      [String.to_atom(filter), args]
    end
  end
end
