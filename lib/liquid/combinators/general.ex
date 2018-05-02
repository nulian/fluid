defmodule Liquid.Combinators.General do
  @moduledoc """
  General purpose combinators used by almost every other combinator
  """
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @space 0x0020
  @point 0x002E
  @question_mark 0x003F
  @underscore 0x005F
  @start_tag "{%"
  @end_tag "%}"
  @start_var "{{"
  @end_var "}}"

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
    concat(
      ignore_whitespaces(),
      string(@end_tag)
    )
    |> ignore()
  end

  @doc """
  Start of liquid Variable
  """
  def start_var do
    concat(
      string(@start_var),
      ignore_whitespaces()
    )
    |> ignore()
  end

  @doc """
  End of liquid Variable
  """
  def end_var do
    ignore_whitespaces()
    |> string(@end_var)
    |> ignore()
  end

  @doc """
  All utf8 valid characters or empty limited by start/end of tag/variable
  """
  def literal do
    repeat_until(utf8_char([]),
                    [
                      string(@start_var),
                      string(@end_var),
                      string(@start_tag),
                      string(@end_tag)
                    ]
                  )
    |> reduce({List, :to_string, []})
    |> tag(:literal)
  end

  @doc """
  Valid variable name represented by:
  /[_A-Za-z][.][_0-9A-Za-z][?]*/
  """
  def name do
    empty()
    |> concat(ignore_whitespaces())
    |> ascii_char([@underscore, ?A..?Z, ?a..?z])
    |> times(ascii_char([@point, @underscore, @question_mark, ?0..?9, ?A..?Z, ?a..?z]), min: 1)
    |> concat(ignore_whitespaces())
    |> reduce({List, :to_string, []})
    |> tag(:name)
  end
end
