defmodule Liquid.Combinators.Expression do
  import NimbleParsec
  alias Liquid.Combinators.General

  def start_tag do
    concat(
      string("{%"),
      General.ignore_whitespaces()
    )
    |> ignore()
  end

  # defparsec(
  #   :end_tag,
  #   concat(
  #     parsec(:ignore_whitespaces),
  #     string("%}")
  #   )
  #   |> ignore()
  # )

  # # Tag =========================================================================

  # # Variable ====================================================================

  # defparsec(
  #   :start_variable,
  #   concat(
  #     string("{{"),
  #     parsec(:ignore_whitespaces)
  #   )
  #   |> ignore()
  # )

  # defparsec(
  #   :end_variable,
  #   concat(
  #     parsec(:ignore_whitespaces),
  #     string("}}")
  #   )
  #   |> ignore()
  # )

  # # Variable ====================================================================
end
