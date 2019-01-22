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
  alias Liquid.Combinators.General

  @type variable_value ::
          {:variable, [parts: [part: String.t(), index: integer() | variable_value]]}
  @type value :: number() | boolean() | nil | String.t() | Range.t() | variable_value()

  # NegativeSign :: -
  @negative_sign ascii_char([?-])

  # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  @digit ascii_char([?0..?9])

  # NonZeroDigit :: Digit but not `0`
  @non_zero_digit ascii_char([?1..?9])

  # IntegerPart ::
  #   - NegativeSign? 0
  #   - NegativeSign? NonZeroDigit Digit*
  @integer_part empty()
                |> optional(@negative_sign)
                |> choice([
                  ascii_char([?0]),
                  @non_zero_digit |> repeat(@digit)
                ])

  # IntValue :: IntegerPart
  @integer_value reduce(@integer_part, {List, :to_integer, []})

  # FractionalPart :: . Digit+
  @fractional_part empty()
                   |> ascii_char([?.])
                   |> times(@digit, min: 1)

  # ExponentIndicator :: one of `e` `E`
  @exponent_indicator ascii_char([?e, ?E])

  # Sign :: one of + -
  @sign ascii_char([?+, ?-])

  # ExponentPart :: ExponentIndicator Sign? Digit+
  @exponent_part @exponent_indicator
                 |> optional(@sign)
                 |> times(@digit, min: 1)

  # FloatValue ::
  #   - IntegerPart FractionalPart
  #   - IntegerPart ExponentPart
  #   - IntegerPart FractionalPart ExponentPart
  @float_value empty()
               |> choice([
                 @integer_part |> concat(@fractional_part) |> concat(@exponent_part),
                 @integer_part |> concat(@fractional_part)
               ])
               |> reduce({List, :to_float, []})

  @double_quoted_string empty()
                        |> ignore(ascii_char([?"]))
                        |> repeat_until(utf8_char([]), [ascii_char([?"])])
                        |> ignore(ascii_char([?"]))

  @quoted_string empty()
                 |> ignore(ascii_char([?']))
                 |> repeat_until(utf8_char([]), [ascii_char([?'])])
                 |> ignore(ascii_char([?']))

  # StringValue ::
  #   - `"` StringCharacter* `"`
  #   - `'` StringCharacter* `'`
  @string_value empty()
                |> choice([@double_quoted_string, @quoted_string])
                |> reduce({List, :to_string, []})

  # BooleanValue : one of `true` `false`
  @boolean_value empty()
                 |> choice([
                   string("true"),
                   string("false")
                 ])
                 |> map({String, :to_atom, []})

  # NullValue : `nil`
  @null_value replace(choice([string("nil"), string("null"), string("NIL"), string("NULL")]), nil)

  def number do
    choice([@float_value, @integer_value])
  end

  defp range_limit(combinator \\ empty(), tag_name) do
    combinator
    |> choice([@integer_value, variable_value()])
    |> unwrap_and_tag(tag_name)
  end

  # RangeValue :: (1..10) | (var..10) | (1..var) | (var1..var2) | (1..var.content[0])
  defp range_value do
    string("(")
    |> ignore()
    |> range_limit(:start)
    |> ignore(string(".."))
    |> concat(range_limit(:end))
    |> ignore(string(")"))
    |> tag(:range)
  end

  # Value[Const] :
  #   - Number
  #   - StringValue
  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]
  #   - Variable
  def value_definition do
    General.ignore_whitespaces()
    |> choice([
      number(),
      @boolean_value,
      @null_value,
      @string_value,
      range_value(),
      variable_value()
    ])
    |> concat(General.ignore_whitespaces())
  end

  def variable_value, do: tag(object_value(), :variable)

  @spec value :: value
  def value do
    parsec(:value_definition)
    |> unwrap_and_tag(:value)
  end

  def object_property do
    string(".")
    |> ignore()
    |> parsec(:variable_part)
    |> optional(times(list_index(), min: 1))
  end

  def variable_part do
    parsec(:variable_definition)
    |> unwrap_and_tag(:part)
  end

  def object_value do
    parsec(:variable_part)
    |> optional(choice([times(list_index(), min: 1), times(object_property(), min: 1)]))
    |> tag(:parts)
    |> optional(parsec(:filters))
  end

  defp list_definition do
    choice([
      @integer_value,
      @string_value,
      parsec(:variable_value)
    ])
  end

  defp list_index do
    string("[")
    |> ignore()
    |> concat(General.ignore_whitespaces())
    |> concat(optional(list_definition()))
    |> concat(General.ignore_whitespaces())
    |> ignore(string("]"))
    |> unwrap_and_tag(:index)
    |> optional(parsec(:object_property))
  end
end
