defmodule Liquid.Combinators.Tags.Assign do
  import NimbleParsec

  alias Liquid.Combinators.General

  def definition do
    string("assign")
    |> ignore()
    |> concat(General.name())
    |> ignore(string("="))
    |> concat(General.name())
    |> tag(:assign)
  end
end
