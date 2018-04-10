defmodule Liquid.Filters do
  @moduledoc """
  Applies a chain of filters passed from Liquid.Variable
  """
  import Kernel, except: [round: 1, abs: 1]
  import Liquid.Utils, only: [to_number: 1]
  alias Liquid.HTML

  defmodule Functions do
    @moduledoc """
    Holds all the basic filter functions used in Liquid 3
    """
    use Timex

    @doc """
    Returns the number of characters in a string or the number of items in an list or a tuple

    ## Examples

        iex> Liquid.Filters.Functions.size("test")
        4
    """
    @spec size(any()) :: integer()
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

    ## Examples

        iex> Liquid.Filters.Functions.downcase("Testy the Test")
        "testy the test"
    """
    @spec downcase(any()) :: String.t()
    def downcase(input) do
      input |> to_string |> String.downcase()
    end

    @doc """
    Makes each character in a string uppercase.
    It has no effect on strings which are already upercase.

    ## Examples

        iex> Liquid.Filters.Functions.upcase("Testy the Test")
        "TESTY THE TEST"
    """
    @spec upcase(any()) :: String.t()
    def upcase(input) do
      input |> to_string |> String.upcase()
    end

    @doc """
    Makes the first character of a string capitalized.

    ## Examples

        iex> Liquid.Filters.Functions.capitalize("testy the test")
        "Testy the test"
    """
    @spec capitalize(any()) :: String.t()
    def capitalize(input) do
      input |> to_string |> String.capitalize()
    end

    @doc """
    Returns the first item of an array.

    ## Examples

        iex> Liquid.Filters.Functions.first(["testy", "the", "test"])
        "testy"
    """
    @spec first(list()) :: any()
    def first(list) when is_list(list), do: list |> List.first()

    @doc """
    Returns the last item of an array.

    ## Examples

        iex> Liquid.Filters.Functions.last(["testy", "the", "test"])
        "test"
    """
    @spec last(list()) :: any()
    def last(list) when is_list(list), do: list |> List.last()

    @doc """
    Reverses the order of the items in an array. reverse cannot reverse a string.

    ## Examples

        iex> Liquid.Filters.Functions.reverse(["testy", "the", "test"])
        ["test", "the", "testy"]
    """
    @spec reverse(list()) :: list()
    def reverse(array), do: array |> to_iterable |> Enum.reverse()

    @doc """
    Sorts items in an array by a property of an item in the array. The order of the sorted array is case-sensitive.

    ## Examples

        iex> Liquid.Filters.Functions.sort(["do", "a", "sort", "by","clown"])
        ["a", "by", "clown", "do", "sort"]
    """
    @spec sort(list()) :: list()
    def sort(array), do: array |> Enum.sort()

    def sort(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.sort_by(& &1[key])
    end

    def sort(array, _) when is_list(array) do
      array |> Enum.sort()
    end

    @doc """
    Removes any duplicate elements in an array.

    ## Examples

        iex> Liquid.Filters.Functions.uniq(["pls", "pls", "remove", "remove","duplicates"])
        ["pls", "remove", "duplicates"]
    """
    @spec uniq(list(), String.t()) :: list() | String.t()
    def uniq(array) when is_list(array), do: array |> Enum.uniq()

    def uniq(_), do: raise("Called `uniq` with non-list parameter.")

    def uniq(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.uniq_by(& &1[key])
    end

    def uniq(array, _) when is_list(array) do
      array |> Enum.uniq()
    end

    def uniq(_, _), do: raise("Called `uniq` with non-list parameter.")

    @doc """
    Combines the items in an array into a single string using the argument as a separator.

    ## Examples

        iex> Liquid.Filters.Functions.join(["1","2","3"], " and ")
        "1 and 2 and 3"
    """
    @spec join(list(), String.t()) :: String.t()
    def join(array, separator \\ " ") do
      array |> to_iterable |> Enum.join(separator)
    end

    @doc """
    Creates an array of values by extracting the values of a named property from another object

    ## Examples

        iex> Liquid.Filters.Functions.map([%{:hallo=>"1", :hola=>"2"}], :hallo)
        "1"
    """
    @spec map(list(), String.t()) :: list() | String.t()
    def map(array, key) when is_list(array) do
      with mapped <- array |> Enum.map(fn arg -> arg[key] end) do
        case Enum.all?(mapped, &is_binary/1) do
          true -> mapped |> Enum.reduce("", fn el, acc -> acc <> el end)
          _ -> mapped
        end
      end
    end

    def map(_, _), do: ""

    @doc """
    Adds a number to another number. Can use strings

    ## Examples

        iex> Liquid.Filters.Functions.plus(100,200)
        300

        iex> Liquid.Filters.Functions.plus("100","200")
        300
    """
    @spec plus(number() | String.t(), number() | String.t()) :: integer()
    def plus(value, operand) when is_number(value) and is_number(operand) do
      value + operand
    end

    def plus(value, operand) when is_number(value) do
      plus(value, to_number(operand))
    end

    def plus(value, operand) do
      value |> to_number |> plus(to_number(operand))
    end

    @doc """
    Subtracts a number from another number. Can use strings

    ## Examples

        iex> Liquid.Filters.Functions.minus(200, 200)
        0

        iex> Liquid.Filters.Functions.minus("200", "200")
        0
    """
    @spec minus(number() | String.t(), number() | String.t()) :: number()
    def minus(value, operand) when is_number(value) and is_number(operand) do
      value - operand
    end

    def minus(value, operand) when is_number(value) do
      minus(value, to_number(operand))
    end

    def minus(value, operand) do
      value |> to_number |> minus(to_number(operand))
    end

    @doc """
    Multiplies a number by another number. Can use strings

    ## Examples

        iex> Liquid.Filters.Functions.times(2, 4)
        8

        iex> Liquid.Filters.Functions.times("2","4")
        8
    """
    @spec times(number() | String.t(), number() | String.t()) :: number()
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

    @doc """
    Divides a number by the specified number. Can use strings

    ## Examples

        iex> Liquid.Filters.Functions.divided_by(12, 2)
        6

        iex> Liquid.Filters.Functions.divided_by("2","0")
        ** (ArithmeticError) divided by 0
    """
    @spec divided_by(number() | String.t(), number() | String.t()) :: number()
    def divided_by(input, operand) when is_number(input) do
      case {input, operand |> to_number} do
        {_, 0} ->
          raise ArithmeticError, message: "divided by 0"

        {input, number_operand} when is_integer(input) ->
          floor(input / number_operand)

        {input, number_operand} ->
          input / number_operand
      end
    end

    def divided_by(input, operand) do
      input |> to_number |> divided_by(operand)
    end

    @doc """
    Rounds a number down to the nearest whole number. tries to convert the input to a number before the 
    filter is applied. Can use strings and you have the option to put a precision number

    ## Examples

        iex> Liquid.Filters.Functions.floor(11.2)
        11

        iex> Liquid.Filters.Functions.floor(11.22222222222,4)
        11.2222
    """
    @spec floor(integer() | number() | String.t()) :: integer() | number()
    def floor(input) when is_integer(input), do: input

    def floor(input) when is_number(input), do: input |> trunc

    def floor(input), do: input |> to_number |> floor

    def floor(input, precision) when is_number(precision) do
      input |> to_number |> Float.floor(precision)
    end

    def floor(input, precision) do
      input |> floor(to_number(precision))
    end

    @doc """
    Rounds the input up to the nearest whole number. Can use strings

    ## Examples

        iex> Liquid.Filters.Functions.ceil(11.2)
        12
    """
    @spec ceil(input :: integer | number | String.t()) :: integer | number
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

    @doc """
    Rounds an input number to the nearest integer or,
    if a number is specified as an argument, to that number of decimal places.

    ## Examples

        iex> Liquid.Filters.Functions.round(11.2)
        11

        iex> Liquid.Filters.Functions.round(11.6)
        12
    """
    @spec round(integer() | number() | String.t()) :: integer() | number()
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
    @spec default(any(), any()) :: any()
    def default(input, default_val \\ "")

    def default(input, default_val) when input in [nil, false, '', "", [], {}, %{}],
      do: default_val

    def default(input, _), do: input

    @doc """
    Returns a single or plural word depending on input number
    """
    @spec pluralize(integer() | number() | String.t(), String.t(), String.t()) :: String.t()
    def pluralize(1, single, _), do: single

    def pluralize(input, _, plural) when is_number(input), do: plural

    def pluralize(input, single, plural), do: input |> to_number |> pluralize(single, plural)

    defdelegate pluralise(input, single, plural), to: __MODULE__, as: :pluralize

    @doc """
    Returns the absolute value of a number.

    ## Examples

        iex> Liquid.Filters.Functions.abs(-17)
        17
    """
    @spec abs(integer() | number() | String.t()) :: integer() | number() | String.t()
    def abs(input) when is_binary(input), do: input |> to_number |> abs

    def abs(input) when input < 0, do: -input

    def abs(input), do: input

    @doc """
    Returns the remainder of a division operation.

    ## Examples

        iex> Liquid.Filters.Functions.modulo(31,4)
        3
    """
    @spec floor(integer() | number() | String.t(), integer() | number() | String.t()) :: integer() | number()
    def modulo(0, _), do: 0

    def modulo(input, operand) when is_number(input) and is_number(operand) and input > 0,
      do: input |> rem(operand)

    def modulo(input, operand) when is_number(input) and is_number(operand) and input < 0,
      do: modulo(input + operand, operand)

    def modulo(input, operand) do
      input |> to_number |> modulo(to_number(operand))
    end

    @doc """
    Shortens a string down to the number of characters passed as a parameter. If the number of characters 
    specified is less than the length of the string, an ellipsis (…) is appended to the string and is 
    included in the character count

    ## Examples

        iex> Liquid.Filters.Functions.truncate("cut this please i need it",18)
        "cut this please..."
    """
    @spec truncate(String.t(), integer(), String.t()) :: String.t()
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

    @doc """
    Shortens a string down to the number of words passed as the argument. 
    If the specified number of words is less than the number of words in the string, 
    an ellipsis (…) is appended to the string

    ## Examples

        iex> Liquid.Filters.Functions.truncatewords("cut this please i need it",3)
        "cut this please..."
    """
    @spec truncatewords(String.t(), integer()) :: String.t()
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

    @doc """
    Replaces every occurrence of an argument in a string with the second argument.

    ## Examples

        iex> Liquid.Filters.Functions.replace("cut this please i need it","cut", "replace")
        "replace this please i need it"
    """
    @spec replace(String.t(), String.t(), String.t()) :: String.t()
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

    @doc """
    Replaces only the first occurrence of the first argument in a string with the second argument.

    ## Examples
        iex> Liquid.Filters.Functions.replace_first("cut this please i need it cut it pls","cut", "replace")
        "replace this please i need it cut it pls"
    """
    @spec replace_first(String.t(), String.t(), String.t()) :: String.t()
    def replace_first(string, from, to \\ "")

    def replace_first(<<string::binary>>, <<from::binary>>, to) do
      string |> String.replace(from, to_string(to), global: false)
    end

    def replace_first(string, from, to) do
      to = to |> to_string
      string |> to_string |> String.replace(to_string(from), to, global: false)
    end

    @doc """
    Removes every occurrence of the specified substring from a string.

    ## Examples

        iex> Liquid.Filters.Functions.remove("cut this please i need it cut it pls","cut")
        " this please i need it  it pls"
    """
    @spec remove(String.t(), String.t()) :: String.t()
    def remove(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "")
    end

    @spec remove_first(String.t(), String.t()) :: String.t()
    def remove_first(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "", global: false)
    end

    def remove_first(string, operand) do
      string |> to_string |> remove_first(to_string(operand))
    end

    @doc """
    Concatenates two strings and returns the concatenated value.

    ## Examples

        iex> Liquid.Filters.Functions.append("this with"," this")
        "this with this"
    """
    @spec append(String.t(), String.t()) :: String.t()
    def append(<<string::binary>>, <<operand::binary>>) do
      string <> operand
    end

    def append(input, nil), do: input

    def append(string, operand) do
      string |> to_string |> append(to_string(operand))
    end

    @doc """
    Adds the specified string to the beginning of another string.

    ## Examples

        iex> Liquid.Filters.Functions.prepend("this with","what is ")
        "what is this with"
    """
    @spec prepend(String.t(), String.t()) :: String.t()
    def prepend(<<string::binary>>, <<addition::binary>>) do
      addition <> string
    end

    def prepend(string, nil), do: string

    def prepend(string, addition) do
      string |> to_string |> append(to_string(addition))
    end

    @doc """
    Removes all whitespace (tabs, spaces, and newlines) from both the left and right side of a string. 
    It does not affect spaces between words.

    ## Examples

        iex> Liquid.Filters.Functions.strip("         this test is just for the strip        ")
        "this test is just for the strip"
    """
    @spec strip(String.t()) :: String.t()
    def strip(<<string::binary>>) do
      String.trim(string)
    end

    @doc """
    Removes all whitespaces (tabs, spaces, and newlines) from the beginning of a string. 
    The filter does not affect spaces between words.

    ## Examples

        iex> Liquid.Filters.Functions.lstrip("         this test is just for the strip     ")
        "this test is just for the strip     "
    """
    @spec lstrip(String.t()) :: String.t()
    def lstrip(<<string::binary>>) do
      String.trim_leading(string)
    end

    @doc """
    Removes all whitespace (tabs, spaces, and newlines) from the right side of a string.

    ## Examples

        iex> Liquid.Filters.Functions.rstrip("         this test is just for the strip     ")
        "         this test is just for the strip"
    """
    @spec rstrip(String.t()) :: String.t()
    def rstrip(<<string::binary>>) do
      String.trim_trailing(string)
    end

    @doc """
    Removes any newline characters (line breaks) from a string.
    """
    @spec strip_newlines(String.t()) :: String.t()
    def strip_newlines(<<string::binary>>) do
      String.replace(string, ~r/\r?\n/, "")
    end

    @doc """
    Replaces every newline (\n) with an HTML line break (<br>).
    """
    @spec newline_to_br(String.t()) :: String.t()
    def newline_to_br(<<string::binary>>) do
      String.replace(string, "\n", "<br />\n")
    end

    @doc """
    Divides an input string into an array using the argument as a separator. split is commonly used to 
    convert comma-separated items from a string to an array.

    ## Examples

        iex> Liquid.Filters.Functions.split("this test is cool", " ")
        ["this", "test", "is", "cool"]
    """
    @spec split(String.t(), String.t()) :: list()
    def split(<<string::binary>>, <<separator::binary>>) do
      String.split(string, separator)
    end

    def split(nil, _), do: []

    @doc """
    Returns a substring of 1 character beginning at the index specified by the argument passed in. 
    An optional second argument specifies the length of the substring to be returned.
    String indices are numbered starting from 0.

    ## Examples

        iex> Liquid.Filters.Functions.slice("this test is cool", 5)
        "test is cool"
    """
    @spec slice(String.t() | list(), integer()) :: String.t() | list()
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

    @doc """
    Escapes a string by replacing characters with escape sequences (so that the string can be used in a URL, 
    for example). It doesn’t change strings that don’t have anything to escape.

    ## Examples

        iex> Liquid.Filters.Functions.escape("Have you read 'James & the Giant Peach'?")
        "Have you read &#39;James &amp; the Giant Peach&#39;?"
    """
    @spec escape(String.t()) :: String.t()
    def escape(input) when is_binary(input) do
      input |> HTML.html_escape()
    end

    defdelegate h(input), to: __MODULE__, as: :escape

    @doc """
    Escapes a string without changing existing escaped entities. It doesn’t change strings that don’t 
    have anything to escape.

    ## Examples

        iex> Liquid.Filters.Functions.escape_once("1 < 2 & 3")
        "1 &lt; 2 &amp; 3"
    """
    @spec escape_once(String.t()) :: String.t()
    def escape_once(input) when is_binary(input) do
      input |> HTML.html_escape_once()
    end

    @doc """
    Removes any HTML tags from a string.

    ## Examples

        iex> Liquid.Filters.Functions.strip_html("Have <em>you</em> read <strong>Ulysses</strong>?")
        "Have you read Ulysses?"
    """
    @spec strip_html(String.t()) :: String.t()
    def strip_html(nil), do: ""

    def strip_html(input) when is_binary(input) do
      input
      |> String.replace(~r/<script.*?<\/script>/m, "")
      |> String.replace(~r/<!--.*?-->/m, "")
      |> String.replace(~r/<style.*?<\/style>/m, "")
      |> String.replace(~r/<.*?>/m, "")
    end

    @doc """
    Converts any URL-unsafe characters in a string into percent-encoded characters.

    ## Examples

        iex> Liquid.Filters.Functions.url_encode("john@test.com")
        "john%40test.com"
    """
    @spec url_encode(String.t()) :: String.t()
    def url_encode(input) when is_binary(input) do
      input |> URI.encode_www_form()
    end

    def url_encode(nil), do: nil

    @doc """
    Converts a timestamp into another date format.

    ## Examples

      iex>  Liquid.Filters.Functions.date("Mon Nov 19 9:45:0 1990")
      "1990-11-19 09:45:00"
    """

    @spec date(String.t() | Date.t(), Date.t() | String.t()) ::
            String.t() | Date.t()
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
        Liquid.quote_matcher() |> Regex.replace(arg, "")
      end

    functions = Functions.__info__(:functions)
    custom_filters = Application.get_env(:liquid, :custom_filters)

    ret =
      case {name, custom_filters[name], functions[name]} do
        # pass value in case of no filters
        {nil, _, _} ->
          value

        # pass non-existend filter
        {_, nil, nil} ->
          value

        # Fallback to standard if no custom
        {_, nil, _} ->
          apply_function(Functions, name, [value | args])

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
