defmodule Liquid.Filters do
  @moduledoc """
  Applies a chain of filters passed from Liquid.Variable
  """

  import Liquid.Utils, only: [to_number: 1]

  @filters_modules [
    Liquid.Filters.Functions,
    Liquid.Filters.Additionals,
    Liquid.Filters.HTML,
    Liquid.Filters.List,
    Liquid.Filters.Math,
  ]

  defmodule Functions do
    @moduledoc """
    Structure that holds all the basic filter functions used in Liquid 3.
    """
    use Timex

    @doc """
    Makes each character in a string lowercase.
    It has no effect on strings which are already all lowercase.
    """
    @spec downcase(any) :: String.t()
    def downcase(input) do
      input |> to_string |> String.downcase()
    end

    def upcase(input) do
      input |> to_string |> String.upcase()
    end

    def capitalize(input) do
      input |> to_string |> String.capitalize()
    end

    @doc """
    Returns a single or plural word depending on input number
    """
    def pluralize(1, single, _), do: single

    def pluralize(input, _, plural) when is_number(input), do: plural

    def pluralize(input, single, plural), do: input |> to_number |> pluralize(single, plural)

    defdelegate pluralise(input, single, plural), to: __MODULE__, as: :pluralize

    def truncate(input, l \\ 50, truncate_string \\ "...")

    def truncate(nil, _, _), do: nil

    def truncate(input, l, truncate_string) when is_number(l) do
      l = l - String.length(truncate_string) - 1

      case {l, String.length(input)} do
        {l, _} when l <= 0 -> truncate_string
        {l, len} when l < len -> String.slice(input, 0..l) <> truncate_string
        _ -> input
      end
    end

    def truncate(input, l, truncate_string), do: truncate(input, to_number(l), truncate_string)

    def truncatewords(input, words \\ 15)

    def truncatewords(nil, _), do: nil

    def truncatewords(input, words) when is_number(words) and words < 1 do
      input |> String.split(" ") |> hd
    end

    def truncatewords(input, words) when is_number(words) do
      truncate_string = "..."
      wordlist = input |> String.split(" ")

      case words - 1 do
        l when l < length(wordlist) ->
          words = wordlist |> Enum.slice(0..l) |> Enum.join(" ")
          words <> truncate_string

        _ ->
          input
      end
    end

    def truncatewords(input, words), do: truncatewords(input, to_number(words))

    def replace(string, from, to \\ "")

    def replace(<<string::binary>>, <<from::binary>>, <<to::binary>>) do
      string |> String.replace(from, to)
    end

    def replace(<<string::binary>>, <<from::binary>>, to) do
      string |> replace(from, to_string(to))
    end

    def replace(<<string::binary>>, from, to) do
      string |> replace(to_string(from), to)
    end

    def replace(string, from, to) do
      string |> to_string |> replace(from, to)
    end

    def replace_first(string, from, to \\ "")

    def replace_first(<<string::binary>>, <<from::binary>>, to) do
      string |> String.replace(from, to_string(to), global: false)
    end

    def replace_first(string, from, to) do
      to = to |> to_string
      string |> to_string |> String.replace(to_string(from), to, global: false)
    end

    def remove(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "")
    end

    def remove_first(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "", global: false)
    end

    def remove_first(string, operand) do
      string |> to_string |> remove_first(to_string(operand))
    end

    def append(<<string::binary>>, <<operand::binary>>) do
      string <> operand
    end

    def append(input, nil), do: input

    def append(string, operand) do
      string |> to_string |> append(to_string(operand))
    end

    def prepend(<<string::binary>>, <<addition::binary>>) do
      addition <> string
    end

    def prepend(string, nil), do: string

    def prepend(string, addition) do
      string |> to_string |> append(to_string(addition))
    end

    def strip(<<string::binary>>) do
      string |> String.trim()
    end

    def lstrip(<<string::binary>>) do
      string |> String.trim_leading()
    end

    def rstrip(<<string::binary>>) do
      string |> String.trim_trailing()
    end

    def split(<<string::binary>>, <<separator::binary>>) do
      String.split(string, separator)
    end

    def split(nil, _), do: []

    def slice(list, from, to) when is_list(list) do
      list |> Enum.slice(from, to)
    end

    def slice(<<string::binary>>, from, to) do
      string |> String.slice(from, to)
    end

    def slice(list, 0) when is_list(list), do: list

    def slice(list, range) when is_list(list) and range > 0 do
      list |> Enum.slice(range, length(list))
    end

    def slice(list, range) when is_list(list) do
      len = length(list)
      list |> Enum.slice(len + range, len)
    end

    def slice(<<string::binary>>, 0), do: string

    def slice(<<string::binary>>, range) when range > 0 do
      string |> String.slice(range, String.length(string))
    end

    def slice(<<string::binary>>, range) do
      len = String.length(string)
      string |> String.slice(len + range, len)
    end

    def slice(nil, _), do: ""
  end

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

    functions = @filters_modules |> Enum.map(&set_module/1) |> List.flatten()
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
