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

  defparsec(:__parse__, repeat_while(definition, {:not_eof, []}))

  definition =
    choice([
      parsec(:__expression__),
      parsec(:__literal__)
    ])

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

  # All utf8 valid characters or empty limited by start/end of tag/variable
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

  liquid_tag =
    start_tag
    |> choice([
      # TODO: Put tag list
      empty(),
      empty(),
    ])
    |> concat(end_tag)

  liquid_variable =
    start_var
    |> concat(literal)
    |> concat(end_var)
    |> tag(:variable)
  # # ## Lexical Tokens

  # # Token ::
  # #   - Punctuator
  # #   - Name
  # #   - IntValue
  # #   - FloatValue
  # #   - StringValue

  # # Punctuator :: one of ! $ ( ) ... : = @ [ ] { | }
  # # Note: No `punctuator` combinator(s) defined; these characters are matched
  # #       explicitly with `ascii_char/1` in other combinators.

  # # Name :: /[_A-Za-z][_0-9A-Za-z]*/
  # def variable_name do
  #   empty()
  #   |> concat(General.ignore_whitespaces())
  #   |> ascii_char([@underscore, ?A..?Z, ?a..?z])
  #   |> times(ascii_char([@point, @underscore, @question_mark, ?0..?9, ?A..?Z, ?a..?z]), min: 1)
  #   |> concat(General.ignore_whitespaces())
  #   |> reduce({List, :to_string, []})
  #   |> tag(:variable_name)
  # end

  # # NegativeSign :: -
  # defp negative_sign, do: ascii_char([?-])

  # # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  # defp digit, do: ascii_char([?0..?9])

  # # NonZeroDigit :: Digit but not `0`
  # defp non_zero_digit, do: ascii_char([?1..?9])

  # # IntegerPart ::
  # #   - NegativeSign? 0
  # #   - NegativeSign? NonZeroDigit Digit*
  # defp integer_part do
  #   empty()
  #   |> optional(negative_sign())
  #   |> choice([
  #     ascii_char([?0]),
  #     non_zero_digit() |> repeat(digit())
  #   ])
  # end

  # # IntValue :: IntegerPart
  # defp int_value do
  #   empty()
  #   |> concat(integer_part())
  #   |> traverse({:build_int_value, []})
  # end

  # def build_int_value(rest, value, context, line, offset) do
  #   do_build_int_value(rest, Enum.reverse(value), context, line, offset)
  # end

  # def do_build_int_value(_rest, [?- | digits], context, _, _) do
  #   {[List.to_integer(digits) * -1], context}
  # end

  # def do_build_int_value(_rest, digits, context, _, _) do
  #   {[List.to_integer(digits)], context}
  # end

  # # FractionalPart :: . Digit+
  # defp fractional_part do
  #   empty()
  #   |> ascii_char([?.])
  #   |> times(digit(), min: 1)
  # end

  # # ExponentIndicator :: one of `e` `E`
  # defp exponent_indicator, do: ascii_char([?e, ?E])

  # # Sign :: one of + -
  # defp sign, do: ascii_char([?+, ?-])

  # # ExponentPart :: ExponentIndicator Sign? Digit+
  # defp exponent_part do
  #   exponent_indicator()
  #   |> optional(sign())
  #   |> times(digit(), min: 1)
  # end

  # # FloatValue ::
  # #   - IntegerPart FractionalPart
  # #   - IntegerPart ExponentPart
  # #   - IntegerPart FractionalPart ExponentPart
  # defp float_value do
  #   empty()
  #   |> choice([
  #     integer_part() |> concat(fractional_part()) |> concat(exponent_part()),
  #     integer_part() |> concat(fractional_part())
  #   ])
  #   |> reduce({List, :to_string, []})
  # end

  # # StringValue ::
  # #   - `"` StringCharacter* `"`
  # defp string_value do
  #   empty()
  #   |> ignore(ascii_char([?"]))
  #   |> repeat_until(utf8_char([]), [utf8_char([?"])])
  #   |> ignore(ascii_char([?"]))
  #   |> reduce({List, :to_string, []})
  # end

  # # BooleanValue : one of `true` `false`
  # defp boolean_value do
  #   choice([
  #     string("true"),
  #     string("false")
  #   ])
  # end

  # # NullValue : `nil`
  # defp null_value, do: string("nil")

  # # ListValue[Const] :
  # #   - [ ]
  # #   - [ Value[?Const]+ ]
  # defp list_value do
  #   choice([
  #     ascii_char([?[])
  #     |> ascii_char([?]]),
  #     ascii_char([?[])
  #     |> times(parsec(:value), min: 1)
  #     |> ascii_char([?]])
  #   ])
  # end

  # # Value[Const] :
  # #   - IntValue
  # #   - FloatValue
  # #   - StringValue
  # #   - BooleanValue
  # #   - NullValue
  # #   - ListValue[?Const]
  # def value do
  #   choice([
  #     int_value(),
  #     float_value(),
  #     string_value(),
  #     boolean_value(),
  #     null_value(),
  #     parsec(:list_value)
  #   ])
  # end
end
