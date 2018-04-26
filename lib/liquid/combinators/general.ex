defmodule Liquid.Combinators.General do
  @moduledoc """
  General purpose combinators used by almost every other combinator
  """
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @newline 0x000A
  @carriage_return 0x000D
  @space 0x0020

  @doc """
  Horizontal Tab (U+0009)
  Space (U+0020)
  """
  def whitespace do
    ascii_char([
      @horizontal_tab,
      @space
    ])
  end

  @doc """
  All utf8 valid characters or empty
  """
  def literal do
    repeat_until(
      utf8_char([]),
      [
        string("{{"),
        string("}}"),
        string("%}"),
        string("{%")
      ]
    )
    |> reduce({List, :to_string, []})
    |> tag(:literal)
  end

  @doc """
  Remove all :whitespace
  """
  def ignore_whitespaces do
    whitespace()
    |> repeat()
    |> ignore()
  end
end
