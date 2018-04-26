defmodule Liquid.Combinators.Expression do
  import NimbleParsec
  alias Liquid.Combinators.General

  # TODO: move start/end tag/var to module General
  def start_tag do
    concat(
      string("{%"),
      General.ignore_whitespaces()
    )
    |> ignore()
  end

  def end_tag do
    concat(
      General.ignore_whitespaces(),
      string("%}")
    )
    |> ignore()
  end

  def start_var do
    concat(
      string("{{"),
      General.ignore_whitespaces()
    )
    |> ignore()
  end

  def end_var do
    concat(
      General.ignore_whitespaces(),
      string("}}")
    )
    |> ignore()
  end

  def var do
    concat(
      start_var(),
      General.literal()
    )
    |> concat(end_var())
    |> tag(:var)
  end
end
