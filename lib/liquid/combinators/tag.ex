defmodule Liquid.Combinators.Tag do
  @moduledoc """
  Helper to create tags
  """
  import NimbleParsec

  def create_generic_tag(tag_name, f \\ &(&1)) do
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string(Atom.to_string(tag_name))))
    |> f.()
    |> concat(parsec(:end_tag))
    |> tag(tag_name)
    |> optional(parsec(:__parse__))
  end
end
