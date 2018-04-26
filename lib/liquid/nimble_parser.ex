defmodule Liquid.NimbleParser do
  import NimbleParsec
  alias Liquid.Combinators.General

  defparsec(:literal, General.literal())
  # defparsec(:parse, concat(parsec(:literal), parsec(:expression)))
end
