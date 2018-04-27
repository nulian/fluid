defmodule Liquid.NimbleParser do
  import NimbleParsec
  alias Liquid.Combinators.{
    General,
    Expression
  }

  defparsec(:literal, General.literal())
  defparsecp(:expression,
    choice([
        Expression.tag(),
        Expression.var()
      ]
    )
  )

  def not_eof("", context, _, _), do: {:halt, context}
  def not_eof(_, context, _, _), do: {:cont, context}

  definition = choice([
    parsec(:expression),
    parsec(:literal),
  ])

  defparsec(:parse,
    repeat_while(definition, {:not_eof, []}))
end
