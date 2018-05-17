defmodule Liquid.Combinators.General do
  @moduledoc """
  General purpose combinators used by almost every other combinator
  """
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @space 0x0020
  @colon 0x003A
  @point 0x002E
  @comma 0x002C
  @single_quote 0x0027
  @quote 0x0022
  @question_mark 0x003F
  @underscore 0x005F
  @dash 0x002D
  @start_tag "{%"
  @end_tag "%}"
  @start_variable "{{"
  @end_variable "}}"
  @start_filter "|"
  @equals "=="
  @does_not_equal "!="
  @greater_than ">"
  @less_than "<"
  @greater_or_equal ">="
  @less_or_equal "<="
  @digit ?0..?9
  @uppercase_letter ?A..?Z
  @lowercase_letter ?a..?z

  def codepoints do
    %{
      horizontal_tab: @horizontal_tab,
      space: @space,
      colon: @colon,
      point: @point,
      comma: @comma,
      quote: @quote,
      single_quote: @single_quote,
      question_mark: @question_mark,
      underscore: @underscore,
      start_tag: @start_tag,
      end_tag: @end_tag,
      start_variable: @start_variable,
      end_variable: @end_variable,
      start_filter: @start_filter,
      digit: @digit,
      uppercase_letter: @uppercase_letter,
      lowercase_letter: @lowercase_letter
    }
  end

  @doc """
  Horizontal Tab (U+0009) + Space (U+0020)
  """
  def whitespace do
    ascii_char([
      @horizontal_tab,
      @space
    ])
  end

  @doc """
  Remove all :whitespace
  """
  def ignore_whitespaces do
    whitespace()
    |> repeat()
    |> ignore()
  end

  @doc """
  Comma without spaces
  """
  def cleaned_comma do
    ignore_whitespaces()
    |> concat(ascii_char([@comma]))
    |> concat(ignore_whitespaces())
    |> ignore()
  end

  @doc """
  Start of liquid Tag
  """
  def start_tag do
    concat(
      string(@start_tag),
      ignore_whitespaces()
    )
    |> ignore()
  end

  @doc """
  End of liquid Tag
  """
  def end_tag do
    ignore_whitespaces()
    |> concat(string(@end_tag))
    |> ignore()
  end

  @doc """
  Start of liquid Variable
  """
  def start_variable do
    concat(
      string(@start_variable),
      ignore_whitespaces()
    )
    |> ignore()
  end

  @doc """
  End of liquid Variable
  """
  def end_variable do
    ignore_whitespaces()
    |> string(@end_variable)
    |> ignore()
  end

  def math_operators do
    choice([
      string(@equals),
      string(@does_not_equal),
      string(@greater_than),
      string(@less_than),
      string(@greater_or_equal),
      string(@less_or_equal),
      string("contains")
    ])
  end

  def logical_operators do
    choice([string("or"), string("and")])
  end

  def or_contition_value do
    string("or")
    |> concat(parsec(:ignore_whitespaces))
    |> concat(
      choice([
        parsec(:number),
        parsec(:string_value),
        parsec(:null_value),
        parsec(:boolean_value)
      ])
    )
    |> parsec(:ignore_whitespaces)
  end

  def comma_contition_value do
    string(",")
    |> concat(parsec(:ignore_whitespaces))
    |> concat(
      choice([
        parsec(:number),
        parsec(:string_value),
        parsec(:null_value),
        parsec(:boolean_value)
      ])
    )
    |> parsec(:ignore_whitespaces)
  end

  @doc """
  All utf8 valid characters or empty limited by start/end of tag/variable
  """
  def literal do
    empty()
    |> repeat_until(utf8_char([]), [
      string(@start_variable),
      string(@end_variable),
      string(@start_tag),
      string(@end_tag)
    ])
    |> reduce({List, :to_string, []})
  end

  defp allowed_chars do
    [
      @digit,
      @uppercase_letter,
      @lowercase_letter,
      @underscore,
      @dash
    ]
  end

  @doc """
  Valid variable name represented by:
  start char [A..Z, a..z, _] plus optional n times [A..Z, a..z, 0..9, _, -]
  """
  def variable_definition do
    empty()
    |> concat(ignore_whitespaces())
    |> utf8_char([@uppercase_letter, @lowercase_letter, @underscore])
    |> optional(times(utf8_char(allowed_chars()), min: 1))
    |> concat(ignore_whitespaces())
    |> reduce({List, :to_string, []})
  end

  def variable_name do
    parsec(:variable_definition)
    |> unwrap_and_tag(:variable_name)
  end

  def liquid_variable do
    start_variable()
    |> concat(variable_name())
    |> concat(end_variable())
    |> tag(:variable)
    |> optional(parsec(:__parse__))
  end

  def single_quoted_token do
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([@single_quote]) |> ignore())
    |> concat(repeat(utf8_char(not: @comma, not: @single_quote)))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(utf8_char([@single_quote]) |> ignore())
    |> concat(parsec(:ignore_whitespaces))
  end

  def double_quoted_token do
    parsec(:ignore_whitespaces)
    |> concat(ascii_char([?"]))
    |> concat(repeat(utf8_char(not: @comma, not: @quote)))
    |> concat(ascii_char([?"]))
    |> reduce({List, :to_string, []})
    |> concat(parsec(:ignore_whitespaces))
  end

  def token do
    choice([double_quoted_token(), single_quoted_token()])
  end

  @doc """
  Filter basic structure, it acepts any kind of filter with the following structure:
  start char: '|' plus flter's parameters as optional: ':' plus optional: parameters values [value]
  """
  def filter_param do
    empty()
    |> optional(ignore(utf8_char([@colon])))
    |> parsec(:ignore_whitespaces)
    |> parsec(:value)
    |> tag(:filter_param)
    |> optional(parsec(:filter))
  end

  @doc """
  Filter parameters structure:  it acepts any kind of parameters with the following structure:
  start char: ':' plus optional: parameters values [value]
  """
  def filter do
    ignore(string(@start_filter))
    |> parsec(:ignore_whitespaces)
    |> parsec(:variable_name)
    |> optional(parsec(:filter_param))
    |> tag(:filter)
    |> optional(parsec(:filter))
  end
end
