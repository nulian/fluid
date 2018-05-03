defmodule Liquid.NimbleParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`
  """
  # TODO: Find methods to split this module
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @space 0x0020
  @start_tag "{%"
  @end_tag "%}"
  @start_variable "{{"
  @end_variable "}}"
  @point 0x002E
  @question_mark 0x003F
  @underscore 0x005F

  ############################### General use combinators  ############################

  # Horizontal Tab (U+0009) + Space (U+0020)
  whitespace = ascii_char([@space, @horizontal_tab])

  # Remove all :whitespace
  ignore_whitespaces =
    whitespace
    |> repeat()
    |> ignore()

  variable_name =
    empty()
    |> concat(ignore_whitespaces)
    |> ascii_char([@underscore, ?A..?Z, ?a..?z])
    |> optional(repeat(ascii_char([@point, @underscore, @question_mark, ?0..?9, ?A..?Z, ?a..?z])))
    |> concat(ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_name)

  defparsec(:variable_name, variable_name)

  start_variable =
    empty()
    |> concat(string(@start_variable))
    |> concat(ignore_whitespaces)
    |> ignore()

  end_variable =
    ignore_whitespaces
    |> concat(string(@end_variable))
    |> ignore()

  liquid_variable =
    start_variable
    |> concat(parsec(:variable_name))
    |> concat(end_variable)
    |> tag(:variable)
    |> optional(parsec(:__parse__))

  defparsec(:liquid_variable, liquid_variable)

  start_tag =
    empty()
    |> string(@start_tag)
    |> concat(ignore_whitespaces)
    |> ignore()

  defparsecp(:start_tag, start_tag)

  end_tag =
    ignore_whitespaces
    |> concat(string(@end_tag))
    |> ignore()

  defparsecp(:end_tag, end_tag)
  ############################### General use combinators  ############################

  ################################        Tags              ###########################

  # |> concat(value)
  assign =
    empty()
    |> parsec(:start_tag)
    |> concat(string("assign"))
    |> ignore()
    |> concat(variable_name)
    |> concat(ignore(string("=")))
    |> concat(parsec(:end_tag))
    |> tag(:assign)
    |> optional(parsec(:__parse__))

  decrement =
    empty()
    |> parsec(:start_tag)
    |> string("decrement")
    |> concat(variable_name)
    |> concat(parsec(:end_tag))
    |> tag(:decrement)
    |> optional(parsec(:__parse__))

  increment =
    empty()
    |> parsec(:start_tag)
    |> string("increment")
    |> concat(variable_name)
    |> concat(parsec(:end_tag))
    |> tag(:increment)
    |> optional(parsec(:__parse__))

  word_raw =
    string("raw")
    |> ignore()

  word_end_raw =
    string("endraw")
    |> ignore()

  open_tag_raw = start_tag |> concat(word_raw) |> concat(end_tag)

  close_tag_raw = start_tag |> concat(word_end_raw) |> concat(end_tag)

  defparsec(:open_tag_raw, open_tag_raw)

  defparsec(:close_tag_raw, close_tag_raw)

  not_close_tag_raw =
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:raw_text)

  defparsecp(:not_close_tag_raw, not_close_tag_raw)

  # |> reduce({List, :to_string, []})
  raw_text =
    empty()
    |> repeat_until(utf8_char([]), [
      string("{%")
    ])
    |> choice([parsec(:close_tag_raw), parsec(:not_close_tag_raw)])
    |> tag(:raw_text)

  defparsec(:raw_text, raw_text)

  raw =
    empty()
    |> parsec(:open_tag_raw)
    |> concat(parsec(:raw_text))
    |> tag(:raw)
    |> optional(parsec(:__parse__))

  defparsec(
    :liquid_tag,
    choice([
      assign,
      decrement,
      increment,
      raw
    ])
  )

  ################################ end Tags #######################################

  ################################## Lexical Tokens ###############################

  # Token ::
  #   - Punctuator
  #   - IntValue
  #   - FloatValue
  #   - StringValue

  # Punctuator :: one of ! $ ( ) ... : = @ [ ] { | }
  # Note: No `punctuator` combinator(s) defined; these characters are matched
  #       explicitly with `ascii_char/1` in other combinators.

  # NegativeSign :: -
  negative_sign = ascii_char([?-])

  # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  digit = ascii_char([?0..?9])

  # NonZeroDigit :: Digit but not `0`
  non_zero_digit = ascii_char([?1..?9])

  # IntegerPart ::
  #   - NegativeSign? 0
  #   - NegativeSign? NonZeroDigit Digit*
  integer_part =
    empty()
    |> optional(negative_sign)
    |> choice([
      ascii_char([?0]),
      non_zero_digit |> repeat(digit)
    ])

  # IntValue :: IntegerPart
  int_value =
    empty()
    |> concat(integer_part)
    |> traverse({:build_int_value, []})

  defp build_int_value(rest, value, context, line, offset) do
    do_build_int_value(rest, Enum.reverse(value), context, line, offset)
  end

  defp do_build_int_value(_rest, [?- | digits], context, _, _) do
    {[List.to_integer(digits) * -1], context}
  end

  defp do_build_int_value(_rest, digits, context, _, _) do
    {[List.to_integer(digits)], context}
  end

  # FractionalPart :: . Digit+
  fractional_part =
    empty()
    |> ascii_char([?.])
    |> times(digit, min: 1)

  # ExponentIndicator :: one of `e` `E`
  exponent_indicator = ascii_char([?e, ?E])

  # Sign :: one of + -
  sign = ascii_char([?+, ?-])

  # ExponentPart :: ExponentIndicator Sign? Digit+
  exponent_part =
    exponent_indicator
    |> optional(sign)
    |> times(digit, min: 1)

  # FloatValue ::
  #   - IntegerPart FractionalPart
  #   - IntegerPart ExponentPart
  #   - IntegerPart FractionalPart ExponentPart
  float_value =
    empty()
    |> choice([
      integer_part |> concat(fractional_part) |> concat(exponent_part),
      integer_part |> concat(fractional_part)
    ])
    |> reduce({List, :to_string, []})

  # StringValue ::
  #   - `"` StringCharacter* `"`
  string_value =
    empty()
    |> ignore(ascii_char([?"]))
    |> repeat_until(utf8_char([]), [utf8_char([?"])])
    |> ignore(ascii_char([?"]))
    |> reduce({List, :to_string, []})

  # BooleanValue : one of `true` `false`
  boolean_value =
    choice([
      string("true"),
      string("false")
    ])

  # NullValue : `nil`
  null_value = string("nil")

  # Value[Const] :
  #   - IntValue
  #   - FloatValue
  #   - StringValue
  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]
  value =
    choice([
      float_value,
      int_value,
      string_value,
      boolean_value,
      null_value,
      parsec(:list_value)
    ])

  defparsec(:value, value)

  # ListValue[Const] :
  #   - [ ]
  #   - [ Value[?Const]+ ]
  list_value =
    choice([
      ascii_char([?[])
      |> ascii_char([?]]),
      ascii_char([?[])
      |> times(parsec(:value), min: 1)
      |> ascii_char([?]])
    ])

  defparsec(:list_value, list_value)

  #################################### End lexical Tokens #####################################

  ########################################### Parser ##########################################

  # All utf8 valid characters or empty limited by start/end of tag/variable
  # Name :: /[_A-Za-z][_0-9A-Za-z]*/
  literal =
    empty()
    |> repeat_until(utf8_char([]), [
      string(@start_variable),
      string(@end_variable),
      string(@start_tag),
      string(@end_tag)
    ])
    |> reduce({List, :to_string, []})
    |> tag(:literal)

  defparsec(
    :__parse__,
    literal
    |> optional(choice([parsec(:liquid_tag), parsec(:liquid_variable)]))
  )

  @doc """
  Valid and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(""), do: {:ok, ""}

  def parse(markup) do
    case __parse__(markup) do
      {:ok, template, "", _, _, _} ->
        {:ok, template}

      {:ok, _, rest, _, _, _} ->
        {:error, "Error parsing: #{rest}"}
    end
  end
end
