defmodule Liquid.Filters.List do
  @moduledoc """
  Applies a chain of 'List' filters passed from Liquid.Variable
  """

  @doc """
  Returns the number of characters in a string or the number of items in an list or a tuple

  ## Examples

    iex> Liquid.Filters.List.size("test")
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
  Returns the first item of an array.

  ## Examples

    iex> Liquid.Filters.List.first(["testy", "the", "test"])
    "testy"
  """
  @spec first(list()) :: any()
  def first(list) when is_list(list), do: list |> List.first()

  @doc """
  Returns the last item of an array.

  ## Examples

    iex> Liquid.Filters.List.last(["testy", "the", "test"])
    "test"
  """
  @spec last(list()) :: any()
  def last(list) when is_list(list), do: list |> List.last()

  @doc """
  Reverses the order of the items in an array. reverse cannot reverse a string.

  ## Examples

    iex> Liquid.Filters.List.reverse(["testy", "the", "test"])
    ["test", "the", "testy"]
  """
  @spec reverse(list()) :: list()
  def reverse(array), do: array |> to_iterable |> Enum.reverse()

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

  @doc """
  Sorts items in an array by a property of an item in the array. The order of the sorted array is case-sensitive.

  ## Examples

    iex> Liquid.Filters.List.sort(["do", "a", "sort", "by","clown"])
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

    iex> Liquid.Filters.List.uniq(["pls", "pls", "remove", "remove","duplicates"])
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

    iex> Liquid.Filters.List.join(["1","2","3"], " and ")
    "1 and 2 and 3"
  """
  @spec join(list(), String.t()) :: String.t()
  def join(array, separator \\ " ") do
    array |> to_iterable |> Enum.join(separator)
  end

  @doc """
  Creates an array of values by extracting the values of a named property from another object

  ## Examples

    iex> Liquid.Filters.List.map([%{:hallo=>"1", :hola=>"2"}], :hallo)
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
end
