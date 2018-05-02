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
  @start_var "{{"
  @end_var "}}"
  @point 0x002E
  @question_mark 0x003F
  @underscore 0x005F

  ###################################### General use combinators  #######################################

  # All utf8 valid characters or empty limited by start/end of tag/variable
  # Name :: /[_A-Za-z][_0-9A-Za-z]*/

  # Horizontal Tab (U+0009) + Space (U+0020)

  whitespace =
    ascii_char([
      @horizontal_tab,
      @space
    ])

  # Remove all :whitespace

  ignore_whitespaces =
    whitespace
    |> repeat()
    |> ignore()

  variable_name =
    empty()
    |> concat(ignore_whitespaces)
    |> ascii_char([@underscore, ?A..?Z, ?a..?z])
    |> times(ascii_char([@point, @underscore, @question_mark, ?0..?9, ?A..?Z, ?a..?z]), min: 1)
    |> concat(ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_name)

  literal =
    empty()
    |> repeat_until(utf8_char([]), [
      string(@start_var),
      string(@end_var),
      string(@start_tag),
      string(@end_tag)
    ])
    |> reduce({List, :to_string, []})
    |> tag(:literal)

  liquid_variable =
    empty()
    |> string(@start_var)
    |> concat(variable_name)
    |> concat(string(@end_var))
    |> tag(:variable)

  ###################################### General use combinators  #######################################

  ######################################        Tags              #######################################
  # |> concat(value)

  liquid_tag =
    choice([
      empty(),
      empty()
    ])

  assign_tag =
    string("assign")
    |> ignore()
    |> concat(variable_name)
    |> ignore(string("="))
    |> tag(:assign)

  decrement =
    string("decrement")
    |> concat(variable_name)

  #   star_for =   # {% for var in vars %}
  #     start_tag #{%
  #     |> concat(string("for"))
  #     |> concat(end_tag)
  #     |> literal
  #
  #
  # close_for =
  #   start_tag
  #   |> concat(string("endfor"))
  #   |> concat(end_tag)
  #
  #
  #   for_tag =
  #       start_for
  #       |> concat(choice([
  #         literal,
  #         tags...
  #         ])
  #       |> concat(end_for)

  # {%for %} {%for%} {%endfor%}{% endfor %} parse

  ######################################        end Tags              #######################################

  ############################################# Lexical Tokens ##########################################

  # # Token ::
  # #   - Punctuator
  # #   - IntValue
  # #   - FloatValue
  # #   - StringValue

  # # Punctuator :: one of ! $ ( ) ... : = @ [ ] { | }
  # # Note: No `punctuator` combinator(s) defined; these characters are matched
  # #       explicitly with `ascii_char/1` in other combinators.

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

  def build_int_value(rest, value, context, line, offset) do
    do_build_int_value(rest, Enum.reverse(value), context, line, offset)
  end

  def do_build_int_value(_rest, [?- | digits], context, _, _) do
    {[List.to_integer(digits) * -1], context}
  end

  def do_build_int_value(_rest, digits, context, _, _) do
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

  value =
    choice([
      int_value,
      float_value,
      string_value,
      boolean_value,
      null_value,
      parsec(:list_value)
    ])

  # ListValue[Const] :
  #   - [ ]
  #   - [ Value[?Const]+ ]
  list_value =
    choice([
      ascii_char([?[])
      |> ascii_char([?]]),
      ascii_char([?[])
      |> times(value, min: 1)
      |> ascii_char([?]])
    ])

  # Value[Const] :
  #   - IntValue
  #   - FloatValue
  #   - StringValue
  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]

  ############################################# End lexical Tokens ##########################################

  ############################################### Parser ##########################################
  @doc """
  Valid and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    case __parse__(markup) do
      {:ok, [template], "", _, _, _} ->
        {:ok, template}

      {:error, err, _, _, _, _} ->
        {:error, err}
    end
  end

  definition =
    choice([
      parsec(:__expression__),
      parsec(:__literal__)
    ])

  defparsec(:__parse__, repeat_while(definition, {:not_eof, []}))

  defparsecp(:__literal__, literal)

  defparsecp(
    :__expression__,
    choice([
      liquid_tag,
      liquid_variable
    ])
  )

  defp not_eof("", context, _, _), do: {:halt, context}
  defp not_eof(_, context, _, _), do: {:cont, context}

  ############################################# End  Parser #############################################
end
