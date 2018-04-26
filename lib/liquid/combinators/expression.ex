defmodule Liquid.Combinators.Expression do


  defparsec(
    :start_tag,
    concat(
      string("{%"),
      parsec(:ignore_whitespaces)
    )
    |> ignore()
  )

  defparsec(
    :end_tag,
    concat(
      parsec(:ignore_whitespaces),
      string("%}")
    )
    |> ignore()
  )

  # Tag =========================================================================

  # Variable ====================================================================

  defparsec(
    :start_variable,
    concat(
      string("{{"),
      parsec(:ignore_whitespaces)
    )
    |> ignore()
  )

  defparsec(
    :end_variable,
    concat(
      parsec(:ignore_whitespaces),
      string("}}")
    )
    |> ignore()
  )

  # Variable ====================================================================
end
