defmodule Liquid.Combinators.Expression do
  @moduledoc """
  A expression in liquid can be either a variable or a tag and are defined here
  """
  import NimbleParsec
  alias Liquid.Combinators.General

  def var do
    concat(
      General.start_var(),
      General.literal()
    )
    |> concat(General.end_var())
    |> tag(:var)
  end

  def tag do
    concat(
      General.start_tag(),
      General.literal()
    )
    |> concat(General.end_tag())
    |> tag(:tag)
  end
end
