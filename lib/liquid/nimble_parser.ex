defmodule Liquid.NimbleParser do
  import NimbleParsec
  alias Liquid.Combinators.{
    General,
    Expression
  }

  defparsecp(:literal, General.literal())
  defparsecp(:expression,
    choice([
        Expression.tag(),
        Expression.var()
      ]
    )
  )

  defparsec(:parse,
    parsec(:literal)
    |> optional(parsec(:expression))
    |> optional(parsec(:literal))
  )
end
