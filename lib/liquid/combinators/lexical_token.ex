defmodule Liquid.Combinators.LexicalToken do
  @moduledoc """
  String with an assigned and thus identified meaning such as
    - Punctuator
    - Number
    - String
    - Boolean
    - List
    - Object
  """
  import NimbleParsec

  # NegativeSign :: -
  def negative_sign, do: ascii_char([?-])

  # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  def digit, do: ascii_char([?0..?9])

  # NonZeroDigit :: Digit but not `0`
  def non_zero_digit, do: ascii_char([?1..?9])

  # IntegerPart ::
  #   - NegativeSign? 0
  #   - NegativeSign? NonZeroDigit Digit*
  def integer_part do
    empty()
    |> optional(negative_sign())
    |> choice([
      ascii_char([?0]),
      non_zero_digit() |> repeat(digit())
    ])
  end

  # IntValue :: IntegerPart
  def integer_value do
    integer_part()
    |> reduce({List, :to_integer, []})
  end

  # FractionalPart :: . Digit+
  def fractional_part do
    empty()
    |> ascii_char([?.])
    |> times(digit(), min: 1)
  end

  # ExponentIndicator :: one of `e` `E`
  def exponent_indicator, do: ascii_char([?e, ?E])

  # Sign :: one of + -
  def sign, do: ascii_char([?+, ?-])

  # ExponentPart :: ExponentIndicator Sign? Digit+
  def exponent_part do
    exponent_indicator()
    |> optional(sign())
    |> times(digit(), min: 1)
  end

  # FloatValue ::
  #   - IntegerPart FractionalPart
  #   - IntegerPart ExponentPart
  #   - IntegerPart FractionalPart ExponentPart
  def float_value do
    empty()
    |> choice([
      integer_part() |> concat(fractional_part()) |> concat(exponent_part()),
      integer_part() |> concat(fractional_part())
    ])
    |> reduce({List, :to_float, []})
  end

  defp double_quoted_string do
    empty()
    |> ignore(ascii_char([?"]))
    |> repeat_until(utf8_char([]), [utf8_char([?"])])
    |> ignore(ascii_char([?"]))
  end

  defp quoted_string do
    empty()
    |> ignore(ascii_char([?']))
    |> repeat_until(utf8_char([]), [utf8_char([?'])])
    |> ignore(ascii_char([?']))
  end

  def to_atom(_rest, [h | _], context, _line, _offset) do
    {h |> String.to_atom() |> List.wrap(), context}
  end

  # StringValue ::
  #   - `"` StringCharacter* `"`
  #   - `'` StringCharacter* `'`
  def string_value do
    empty()
    |> choice([double_quoted_string(), quoted_string()])
    |> reduce({List, :to_string, []})
  end

  # SingleStringValue ::
  #   - `'` StringCharacter* `'`
  def single_string_value do
    empty()
    |> ignore(ascii_char([?']))
    |> repeat_until(utf8_char([]), [utf8_char([?'])])
    |> ignore(ascii_char([?']))
    |> reduce({List, :to_string, []})
  end

  # BooleanValue : one of `true` `false`
  def boolean_value do
    empty()
    |> choice([
      string("true"),
      string("false")
    ])
    |> traverse({Liquid.Combinators.LexicalToken, :to_atom, []})
  end

  # NullValue : `nil`
  def null_value do
    empty()
    |> choice([string("nil"), string("null")])
    |> replace(nil)
  end

  def number do
    choice([float_value(), integer_value()])
  end

  defp range_part(combinator \\ empty(), tag_name) do
    combinator
    |> choice([integer_value(), parsec(:variable_definition)])
    |> unwrap_and_tag(tag_name)
  end

  # RangeValue :: (1..10) | (var..10) | (1..var) | (var1..var2)
  def range_value do
    string("(")
    |> ignore()
    |> parsec(:ignore_whitespaces)
    |> range_part(:start)
    |> ignore(string(".."))
    |> concat(range_part(:end))
    |> parsec(:ignore_whitespaces)
    |> ignore(string(")"))
    |> tag(:range_value)
  end

  # Value[Const] :
  #   - Number
  #   - StringValue
  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]
  #   - Variable
  def value_definition do
    parsec(:ignore_whitespaces)
    |> choice([
      number(),
      boolean_value(),
      null_value(),
      string_value(),
      variable_value()
    ])
    |> concat(parsec(:ignore_whitespaces))
  end

  def variable_value, do: tag(object_value(), :variable)

  def value do
    parsec(:value_definition)
    |> unwrap_and_tag(:value)
  end

  def object_property do
    string(".")
    |> ignore()
    |> parsec(:object_value)
  end

  def object_value do
    parsec(:variable_definition)
    |> optional(choice([times(list_index(), min: 1), parsec(:object_property)]))
  end

  defp list_definition do
    choice([
      integer_value(),
      parsec(:variable_value)
    ])
  end

  defp list_index do
    string("[")
    |> ignore()
    |> parsec(:ignore_whitespaces)
    |> concat(optional(list_definition()))
    |> parsec(:ignore_whitespaces)
    |> ignore(string("]"))
    |> unwrap_and_tag(:index)
    |> optional(parsec(:object_property))
  end
end
