defmodule Liquid.Filters.Math do
  @moduledoc """
  Applies a chain of 'Math' filters passed from Liquid.Variable
  """
  import Kernel, except: [round: 1, abs: 1, floor: 1, ceil: 1]
  import Liquid.Utils, only: [to_number: 1]

  @doc """
  Adds a number to another number. Can use strings

  ## Examples

    iex> Liquid.Filters.Math.plus(100, 200)
    300

    iex> Liquid.Filters.Math.plus("100", "200")
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

    iex> Liquid.Filters.Math.minus(200, 200)
    0

    iex> Liquid.Filters.Math.minus("200", "200")
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

    iex> Liquid.Filters.Math.times(2, 4)
    8

    iex> Liquid.Filters.Math.times("2","4")
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

  @doc """
  Divides a number by the specified number. Can use strings

  ## Examples

    iex> Liquid.Filters.Math.divided_by(12, 2)
    6

    iex> Liquid.Filters.Math.divided_by("2","0")
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

    iex> Liquid.Filters.Math.floor(11.2)
    11

    iex> Liquid.Filters.Math.floor(11.22222222222,4)
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

    iex> Liquid.Filters.Math.ceil(11.2)
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

    iex> Liquid.Filters.Math.round(11.2)
    11

    iex> Liquid.Filters.Math.round(11.6)
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
  Returns the absolute value of a number.

  ## Examples

    iex> Liquid.Filters.Math.abs(-17)
    17
  """
  @spec abs(integer() | number() | String.t()) :: integer() | number() | String.t()
  def abs(input) when is_binary(input), do: input |> to_number |> abs

  def abs(input) when input < 0, do: -input

  def abs(input), do: input

  @doc """
  Returns the remainder of a division operation.

  ## Examples

    iex> Liquid.Filters.Math.modulo(31,4)
    3
  """
  @spec modulo(integer() | number() | String.t(), integer() | number() | String.t()) ::
          integer() | number()
  def modulo(0, _), do: 0

  def modulo(input, operand) when is_number(input) and is_number(operand) and input > 0,
    do: input |> rem(operand)

  def modulo(input, operand) when is_number(input) and is_number(operand) and input < 0,
    do: modulo(input + operand, operand)

  def modulo(input, operand) do
    input |> to_number |> modulo(to_number(operand))
  end
end
