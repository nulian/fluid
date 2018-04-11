defmodule Liquid.Filters.String do
  @moduledoc """
  Applies a chain of 'String' filters passed from Liquid.Variable
  """
  import Kernel, except: [round: 1, abs: 1]
  import Liquid.Utils, only: [to_number: 1]

  alias Liquid.{HTML, Filters}

  use Timex

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
  Returns a single or plural word depending on input number
  """
  @spec pluralize(integer() | number() | String.t(), String.t(), String.t()) :: String.t()
  def pluralize(1, single, _), do: single

  def pluralize(input, _, plural) when is_number(input), do: plural

  def pluralize(input, single, plural), do: input |> to_number |> pluralize(single, plural)

  defdelegate pluralise(input, single, plural), to: __MODULE__, as: :pluralize

end