defmodule Liquid.Filters do
  @moduledoc """
  Applies a chain of filters passed from Liquid.Variable
  """

  @filters_modules [
    Liquid.Filters.Additionals,
    Liquid.Filters.HTML,
    Liquid.Filters.List,
    Liquid.Filters.Math,
    Liquid.Filters.String
  ]

  @doc """
  Recursively pass through all of the input filters applying them
  """
  @spec filter(list(), String.t()) :: String.t() | list()
  def filter([], value), do: value

  def filter([filter | rest], value) do
    [name, args] = filter

    args =
      for arg <- args do
        Regex.replace(Liquid.quote_matcher(), arg, "")
      end

    functions = @filters_modules |> Enum.map(&set_module(&1)) |> List.flatten()
    custom_filters = Application.get_env(:liquid, :custom_filters)

    ret =
      case {name, custom_filters[name], functions[name]} do
        # pass value in case of no filters
        {nil, _, _} ->
          value

        # pass non-existent filter
        {_, nil, nil} ->
          value

        # Fallback to standard if no custom
        {_, nil, _} ->
          apply_function(functions[name], name, [value | args])

        _ ->
          apply_function(custom_filters[name], name, [value | args])
      end

    filter(rest, ret)
  end

  @doc """
  Add filter modules mentioned in extra_filter_modules env variable
  """
  def add_filter_modules do
    for filter_module <- Application.get_env(:liquid, :extra_filter_modules) || [] do
      filter_module |> add_filters
    end
  end

  @doc """
  Fetches the current custom filters and extends with the functions from passed module
  You can override the standard filters with custom filters
  """
  def add_filters(module) do
    custom_filters = Application.get_env(:liquid, :custom_filters) || %{}

    module_functions =
      module.__info__(:functions)
      |> Enum.into(%{}, fn {key, _} -> {key, module} end)

    custom_filters = module_functions |> Map.merge(custom_filters)
    Application.put_env(:liquid, :custom_filters, custom_filters)
  end

  def set_module(module) do
    Enum.map(module.__info__(:functions), fn {fname, _} -> {fname, module} end)
  end

  defp apply_function(module, name, args) do
    try do
      apply(module, name, args)
    rescue
      e in UndefinedFunctionError ->
        functions = module.__info__(:functions)

        raise ArgumentError,
          message: "Liquid error: wrong number of arguments (#{e.arity} for #{functions[name]})"
    end
  end
end
