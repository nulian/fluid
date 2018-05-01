defmodule Liquid.Combinators.Tags.Assign do
  import NimbleParsec

  alias Liquid.Combinators.Token

  def definition do
    string("assign")
    |> ignore()
    |> concat(Token.variable_name())
    |> ignore(string("="))
    # |> concat(Token.value())
    |> tag(:assign)
  end
end
