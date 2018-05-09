defmodule Liquid.NimbleParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`
  """
  # TODO: Find methods to split this module
  import NimbleParsec

  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tags.{
    Raw
  }

  defparsec(:liquid_variable, General.liquid_variable())
  defparsec(:variable_name, General.variable_name())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:ignore_whitespaces, General.ignore_whitespaces())

  ################################        Tags              ###########################

  assign =
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string("assign")))
    |> concat(parsec(:variable_name))
    |> concat(ignore(string("=")))
    |> concat(parsec(:value))
    |> concat(parsec(:end_tag))
    |> tag(:assign)
    |> optional(parsec(:__parse__))

  defparsec(:assign, assign)

  decrement =
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string("decrement")))
    |> concat(parsec(:variable_name))
    |> concat(parsec(:end_tag))
    |> tag(:decrement)
    |> optional(parsec(:__parse__))

  defparsec(:decrement, decrement)

  increment =
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string("increment")))
    |> concat(parsec(:variable_name))
    |> concat(parsec(:end_tag))
    |> tag(:increment)
    |> optional(parsec(:__parse__))

  defparsec(:increment, increment)

  ################################           raw          ###########################

  defparsec(:open_tag_raw, Raw.open_tag())
  defparsec(:close_tag_raw, Raw.close_tag())

  not_close_tag_raw =
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:raw_content)

  defparsecp(:not_close_tag_raw, not_close_tag_raw)

  raw_content =
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag)
    ])
    |> choice([parsec(:close_tag_raw), parsec(:not_close_tag_raw)])
    |> reduce({List, :to_string, []})
    |> tag(:raw_content)

  defparsec(:raw_content, raw_content)

  raw =
    empty()
    |> parsec(:open_tag_raw)
    |> concat(parsec(:raw_content))
    |> tag(:raw)
    |> optional(parsec(:__parse__))

  defparsec(:raw, raw)
  ##############################           raw            ###########################

  ###############################        comment          ###########################
  not_end_comment =
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:comment_content)

  defparsecp(:not_end_comment, not_end_comment)

  end_comment =
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endcomment"))
    |> concat(parsec(:end_tag))

  defparsecp(:end_comment, end_comment)

  comment_content =
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag)
    ])
    |> choice([parsec(:end_comment), parsec(:not_end_comment)])

  defparsecp(:comment_content, comment_content)

  comment =
    empty()
    |> parsec(:start_tag)
    |> ignore(string("comment"))
    |> concat(parsec(:end_tag))
    |> ignore(parsec(:comment_content))
    |> optional(parsec(:__parse__))

  defparsec(:comment, comment)

  ################################        comment          ###########################

  ################################        include          ###########################
  snippet_var =
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([General.codepoints().apostrophe]))
    |> ascii_char([General.codepoints().underscore, ?A..?Z, ?a..?z])
    |> optional(
      repeat(
        ascii_char([
          General.codepoints().point,
          General.codepoints().underscore,
          General.codepoints().question_mark,
          ?0..?9,
          ?A..?Z,
          ?a..?z
        ])
      )
    )
    |> ascii_char([General.codepoints().apostrophe])
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:snippet)

  defparsecp(:snippet_var, snippet_var)

  variable_atom =
    empty()
    |> parsec(:ignore_whitespaces)
    |> ascii_char([General.codepoints().underscore, ?A..?Z, ?a..?z])
    |> optional(
      repeat(
        ascii_char([
          General.codepoints().point,
          General.codepoints().underscore,
          General.codepoints().question_mark,
          ?0..?9,
          ?A..?Z,
          ?a..?z
        ])
      )
    )
    |> concat(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_atom)

  defparsec(:variable_atom, variable_atom)

  var_assignation =
    General.cleaned_comma()
    |> concat(parsec(:variable_atom))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> parsec(:ignore_whitespaces)
    |> optional(parsec(:var_assignation))

  defparsecp(:var_assignation, var_assignation)

  # {% include 'color' with 'red' %}
  with_param =
    empty()
    |> ignore(string("with"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:with_param)

  defparsecp(:with_param, with_param)

  # {% include 'color' for 'red' %}
  for_param =
    empty()
    |> ignore(string("for"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:for_param)

  defparsecp(:for_param, for_param)

  include =
    empty()
    |> parsec(:start_tag)
    |> ignore(string("include"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> optional(choice([parsec(:with_param), parsec(:for_param), parsec(:var_assignation)]))
    |> concat(parsec(:end_tag))
    |> tag(:include)
    |> optional(parsec(:__parse__))

  defparsec(:include, include)

  ################################       end include       ###########################
  ################################        cycle            ###########################

  word_cycle =
    string("cycle")
    |> ignore()

  quoted = ascii_char([?"])

  apostrophe =
    string("'")
    |> ignore()

  coma =
    string(",")
    |> ignore()

  defparsec(:coma, coma)

  single_quoted_string =
    parsec(:ignore_whitespaces)
    |> concat(apostrophe)
    |> concat(repeat(utf8_char(not: ?,, not: ?')))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(apostrophe)
    |> concat(parsec(:ignore_whitespaces))

  defparsec(:single_quoted_string, single_quoted_string)

  double_quoted_string =
    parsec(:ignore_whitespaces)
    |> concat(quoted)
    |> concat(repeat(utf8_char(not: ?,, not: ?")))
    |> concat(quoted)
    |> reduce({List, :to_string, []})
    |> concat(parsec(:ignore_whitespaces))

  defparsec(:double_quoted_string, double_quoted_string)

  integer_value = integer(min: 1)

  defparsec(:integer_value, integer_value)

  cycle_group =
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:single_quoted_string),
        parsec(:double_quoted_string),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> reduce({List, :to_string, []})
    |> concat(utf8_char([?:]) |> ignore())

  defparsec(:cycle_group, cycle_group)

  last_cycle_value =
    parsec(:ignore_whitespaces)
    |> choice([
      parsec(:single_quoted_string),
      parsec(:double_quoted_string),
      parsec(:integer_value)
    ])
    |> concat(parsec(:end_tag))
    |> reduce({List, :to_string, []})

  defparsec(:last_cycle_value, last_cycle_value)

  cycle_values =
    empty()
    |> choice([
      parsec(:single_quoted_string),
      parsec(:double_quoted_string),
      parsec(:integer_value)
    ])
    |> concat(parsec(:ignore_whitespaces))
    |> concat(coma)
    |> reduce({List, :to_string, []})
    |> choice([parsec(:cycle_values), parsec(:last_cycle_value)])

  defparsec(:cycle_values, cycle_values)

  cycle =
    empty()
    |> parsec(:start_tag)
    |> concat(word_cycle)
    |> concat(optional(parsec(:cycle_group)))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(choice([parsec(:cycle_values), parsec(:last_cycle_value)]))
    |> tag(:cycle)
    |> optional(parsec(:__parse__))

  defparsec(:cycle, cycle)

  ############################        end of cycle       ##########################

  defparsec(
    :liquid_tag,
    choice([
      assign,
      decrement,
      increment,
      parsec(:raw),
      parsec(:include),
      parsec(:cycle),
      parsec(:comment)
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
    |> reduce({List, :to_integer, []})

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
    |> reduce({List, :to_float, []})

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
    General.ignore_whitespaces()
    |> choice([
      float_value,
      int_value,
      string_value,
      boolean_value,
      null_value,
      parsec(:list_value)
    ])
    |> concat(parsec(:ignore_whitespaces))
    |> unwrap_and_tag(:value)

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

  defparsec(
    :__parse__,
    General.literal()
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
