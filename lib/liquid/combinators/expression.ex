defmodule Liquid.Combinators.Expression do
  @moduledoc """
  A expression in liquid can be either a variable or a tag and are defined here
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Token}

  alias Liquid.Combinators.Tags.{
    Assign
  }

  def decrement do
    string("decrement")
    |> concat(Token.variable_name())
  end

  liquid_variable =
    concat(
      General.start_var(),
      General.literal()
    )
    |> concat(General.end_var())
    |> tag(:var)

  liquid_tag =
    General.start_tag()
    |> choice([
      Assign.definition(),
      decrement()
    ])
    |> concat(General.start_tag())
end
