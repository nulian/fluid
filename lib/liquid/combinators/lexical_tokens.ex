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

  # StringValue ::
  #   - `"` StringCharacter* `"`
  def string_value do
    empty()
    |> ignore(ascii_char([?"]))
    |> repeat_until(utf8_char([]), [utf8_char([?"])])
    |> ignore(ascii_char([?"]))
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
  def null_value, do: string("nil")

  def number do
    choice([int_value(), float_value()])
  end

  # Value[Const] :
  #   - IntValue
  #   - FloatValue
  #   - StringValue
  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]
  def value do
    parsec(:ignore_whitespaces)
    |> choice([
      float_value(),
      int_value(),
      string_value(),
      boolean_value(),
      null_value(),
      parsec(:list_value)
    ])
    |> concat(parsec(:ignore_whitespaces))
    |> unwrap_and_tag(:value)
  end

  # ListValue[Const] :
  #   - [ ]
  #   - [ Value[?Const]+ ]
  def list_value do
    choice([
      ascii_char([?[])
      |> ascii_char([?]]),
      ascii_char([?[])
      |> times(parsec(:value), min: 1)
      |> ascii_char([?]])
    ])
  end
end