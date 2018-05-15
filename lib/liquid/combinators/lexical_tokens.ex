defmodule Liquid.Combinators.LexicalTokens do
  import NimbleParsec

  # Token ::
  #   - Punctuator
  #   - IntValue
  #   - FloatValue
  #   - StringValue

  # Punctuator :: one of ! $ ( ) ... : = @ [ ] { | }
  # Note: No `punctuator` combinator(s) defined; these characters are matched
  #       explicitly with `ascii_char/1` in other combinators.

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
  def int_value do
    empty()
    |> concat(integer_part())
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

  # StringValue ::
  #   - `"` StringCharacter* `"`
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
    choice([
      string("true"),
      string("false")
    ])
  end

  # NullValue : `nil`
  def null_value, do: choice([string("nil"), string("null")])

  def number do
    choice([float_value(), int_value()])
  end

  # RangeValue : (1..10) (my_var..10) (1..my_var)

  # IntValue :: IntegerPart
  def int_value_string do
    empty()
    |> concat(integer_part())
   end

  def range_value do
    string("(")
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:variable_definition), int_value_string()]))
    |> reduce({List, :to_string, []})
    |> concat(string("."))
    |> concat(string("."))
    |> concat(choice([parsec(:variable_definition), int_value_string()]))
    |> reduce({List, :to_string, []})
    |> parsec(:ignore_whitespaces)
    |> concat(string(")"))
    |> reduce({List, :to_string, []})
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
      string_value(),
      boolean_value(),
      null_value(),
      object_value()
    ])
    |> concat(parsec(:ignore_whitespaces))
  end

  def value do
    parsec(:value_definition)
    |> unwrap_and_tag(:value)
  end

  # ObjectValue[Const] :
  #   - [ ]
  #   - [ Value[?Const]+ ]
  def object_property do
  string(".")
  |> parsec(:object_value)
  end

  def object_value do
    parsec(:variable_definition)
    |> optional(choice([times(list_index(), min: 1), parsec(:object_property)]))
    |> reduce({Enum, :join, []})
  end

  defp list_definition do
    choice([
      int_value(),
      parsec(:variable_definition)
    ])
  end

  defp list_index do
    string("[")
    |> parsec(:ignore_whitespaces)
    |> concat(optional(list_definition()))
    |> parsec(:ignore_whitespaces)
    |> concat(string("]"))
    |> optional(parsec(:object_property))
  end


end
