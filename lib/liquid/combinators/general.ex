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
  @apostrophe 0x0027
  @question_mark 0x003F
  @underscore 0x005F
  @start_tag "{%"
  @end_tag "%}"
  @start_variable "{{"
  @end_variable "}}"

  def codepoints do
    %{
      horizontal_tab: @horizontal_tab,
      space: @space,
      colon: @colon,
      point: @point,
      comma: @comma,
      apostrophe: @apostrophe,
      question_mark: @question_mark,
      underscore: @underscore,
      start_tag: @start_tag,
      end_tag: @end_tag,
      start_variable: @start_variable,
      end_variable: @end_variable
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

  @doc """
  Valid variable name represented by:
  /[_A-Za-z][.][_0-9A-Za-z][?]*/
  """
  def variable_name do
    empty()
    |> concat(ignore_whitespaces())
    |> ascii_char([@underscore, ?A..?Z, ?a..?z])
    |> optional(repeat(ascii_char([@point, @underscore, @question_mark, ?0..?9, ?A..?Z, ?a..?z])))
    |> concat(ignore_whitespaces())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:variable_name)
  end

  def liquid_variable do
    start_variable()
    |> concat(variable_name())
    |> concat(end_variable())
    |> tag(:variable)
    |> optional(parsec(:__parse__))
  end
end
