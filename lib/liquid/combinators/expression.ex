defmodule Liquid.Combinators.Expression do
  @moduledoc """
  A expression in liquid can be either a variable or a tag and are defined here
  """
  import NimbleParsec
  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tags.{
    Assign
  }

  def var do
    concat(
      General.start_var(),
      General.literal()
    )
    |> concat(General.end_var())
    |> tag(:var)
  end

  def decrement do
    string("decrement")
    |> concat(General.name())
  end

  def tag do
    General.start_tag()
    |> choice([
        Assign.definition(),
        decrement()
      ]
    )
    |> concat(General.start_tag())
  end
end
