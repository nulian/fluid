defmodule Liquid.Filters do
  @moduledoc """
  Applies a chain of filters passed from Liquid.Variable
  """
  import Kernel, except: [round: 1, abs: 1]
  import Liquid.Utils, only: [to_number: 1]
  alias Liquid.HTML

  @filters_modules [
    Liquid.Filters.Functions
  ]

  defmodule Functions do
    @moduledoc """
    Structure that holds all the basic filter functions used in Liquid 3.
    """
    use Timex

    def size(input) when is_binary(input) do
      String.length(input)
    end

    def size(input) when is_list(input) do
      length(input)
    end

    def size(input) when is_tuple(input) do
      tuple_size(input)
    end

    def size(_), do: 0

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

    def first(array) when is_list(array), do: array |> List.first()

    def last(array) when is_list(array), do: array |> List.last()

    def reverse(array), do: array |> to_iterable |> Enum.reverse()

    def sort(array), do: array |> Enum.sort()

    def sort(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.sort_by(& &1[key])
    end

    def sort(array, _) when is_list(array) do
      array |> Enum.sort()
    end

    def uniq(array) when is_list(array), do: array |> Enum.uniq()

    def uniq(_), do: raise("Called `uniq` with non-list parameter.")

    def uniq(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.uniq_by(& &1[key])
    end

    def uniq(array, _) when is_list(array) do
      array |> Enum.uniq()
    end

    def uniq(_, _), do: raise("Called `uniq` with non-list parameter.")

    def join(array, separator \\ " ") do
      array |> to_iterable |> Enum.join(separator)
    end

    def map(array, key) when is_list(array) do
      with mapped <- array |> Enum.map(fn arg -> arg[key] end) do
        case Enum.all?(mapped, &is_binary/1) do
          true -> mapped |> Enum.reduce("", fn el, acc -> acc <> el end)
          _ -> mapped
        end
      end
    end

    def map(_, _), do: ""

    def plus(value, operand) when is_number(value) and is_number(operand) do
      value + operand
    end

    def plus(value, operand) when is_number(value) do
      plus(value, to_number(operand))
    end

    def plus(value, operand) do
      value |> to_number |> plus(to_number(operand))
    end

    def minus(value, operand) when is_number(value) and is_number(operand) do
      value - operand
    end

    def minus(value, operand) when is_number(value) do
      minus(value, to_number(operand))
    end

    def minus(value, operand) do
      value |> to_number |> minus(to_number(operand))
    end

    def times(value, operand) when is_integer(value) and is_integer(operand) do
      value * operand
    end

    def times(value, operand) do
      {value_int, value_len} = value |> get_int_and_counter
      {operand_int, operand_len} = operand |> get_int_and_counter

      case value_len + operand_len do
        0 ->
          value_int * operand_int

        precision ->
          Float.round(value_int * operand_int / :math.pow(10, precision), precision)
      end
    end

    def divided_by(input, operand) when is_number(input) do
      case {input, operand |> to_number} do
        {_, 0} ->
          raise ArithmeticError, message: "divided by 0"

        {input, number_operand} when is_integer(input) ->
          (input / number_operand) |> floor

        {input, number_operand} ->
          input / number_operand
      end
    end

    def divided_by(input, operand) do
      input |> to_number |> divided_by(operand)
    end

    def floor(input) when is_integer(input), do: input

    def floor(input) when is_number(input), do: input |> trunc

    def floor(input), do: input |> to_number |> floor

    def floor(input, precision) when is_number(precision) do
      input |> to_number |> Float.floor(precision)
    end

    def floor(input, precision) do
      input |> floor(to_number(precision))
    end

    def ceil(input) when is_integer(input), do: input

    def ceil(input) when is_number(input) do
      input |> Float.ceil() |> trunc
    end

    def ceil(input), do: input |> to_number |> ceil

    def ceil(input, precision) when is_number(precision) do
      input |> to_number |> Float.ceil(precision)
    end

    def ceil(input, precision) do
      input |> ceil(to_number(precision))
    end

    def round(input) when is_integer(input), do: input

    def round(input) when is_number(input) do
      input |> Float.round() |> trunc
    end

    def round(input), do: input |> to_number |> round

    def round(input, precision) when is_number(precision) do
      input |> to_number |> Float.round(precision)
    end

    def round(input, precision) do
      input |> round(to_number(precision))
    end

    @doc """
    Allows you to specify a fallback in case a value doesn’t exist.
    `default` will show its value if the left side is nil, false, or empty
    """
    @spec default(any, any) :: any
    def default(input, default_val \\ "")

    def default(input, default_val) when input in [nil, false, '', "", [], {}, %{}],
      do: default_val

    def default(input, _), do: input

    @doc """
    Returns a single or plural word depending on input number
    """
    def pluralize(1, single, _), do: single

    def pluralize(input, _, plural) when is_number(input), do: plural

    def pluralize(input, single, plural), do: input |> to_number |> pluralize(single, plural)

    defdelegate pluralise(input, single, plural), to: __MODULE__, as: :pluralize

    def abs(input) when is_binary(input), do: input |> to_number |> abs

    def abs(input) when input < 0, do: -input

    def abs(input), do: input

    def modulo(0, _), do: 0

    def modulo(input, operand) when is_number(input) and is_number(operand) and input > 0,
      do: input |> rem(operand)

    def modulo(input, operand) when is_number(input) and is_number(operand) and input < 0,
      do: modulo(input + operand, operand)

    def modulo(input, operand) do
      input |> to_number |> modulo(to_number(operand))
    end

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

    def strip_newlines(<<string::binary>>) do
      string |> String.replace(~r/\r?\n/, "")
    end

    def newline_to_br(<<string::binary>>) do
      string |> String.replace("\n", "<br />\n")
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

    def escape(input) when is_binary(input) do
      input |> HTML.html_escape()
    end

    defdelegate h(input), to: __MODULE__, as: :escape

    def escape_once(input) when is_binary(input) do
      input |> HTML.html_escape_once()
    end

    def strip_html(nil), do: ""

    def strip_html(input) when is_binary(input) do
      input
      |> String.replace(~r/<script.*?<\/script>/m, "")
      |> String.replace(~r/<!--.*?-->/m, "")
      |> String.replace(~r/<style.*?<\/style>/m, "")
      |> String.replace(~r/<.*?>/m, "")
    end

    def url_encode(input) when is_binary(input) do
      input |> URI.encode_www_form()
    end

    def url_encode(nil), do: nil

    def date(input, format \\ "%F %T")

    def date(nil, _), do: nil

    def date(input, format) when is_nil(format) or format == "" do
      input |> date
    end

    def date("now", format), do: Timex.now() |> date(format)

    def date("today", format), do: Timex.now() |> date(format)

    def date(input, format) when is_binary(input) do
      with {:ok, input_date} <- NaiveDateTime.from_iso8601(input) do
        input_date |> date(format)
      else
        {:error, :invalid_format} ->
          with {:ok, input_date} <- Timex.parse(input, "%a %b %d %T %Y", :strftime),
               do: input_date |> date(format)
      end
    end

    def date(input, format) do
      with {:ok, date_str} <- Timex.format(input, format, :strftime), do: date_str
    end

    # Helpers

    defp to_iterable(input) when is_list(input) do
      case List.first(input) do
        first when is_nil(first) -> []
        first when is_tuple(first) -> [input]
        _ -> input |> List.flatten()
      end
    end

    defp to_iterable(input) do
      # input when is_map(input) -> [input]
      # input when is_tuple(input) -> input
      List.wrap(input)
    end

    defp get_int_and_counter(input) when is_integer(input), do: {input, 0}

    defp get_int_and_counter(input) when is_number(input) do
      {_, remainder} = input |> Float.to_string() |> Integer.parse()
      len = String.length(remainder) - 1
      new_value = input * :math.pow(10, len)
      new_value = new_value |> Float.round() |> trunc
      {new_value, len}
    end

    defp get_int_and_counter(input) do
      input |> to_number |> get_int_and_counter
    end
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
