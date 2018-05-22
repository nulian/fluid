defmodule Liquid.Combinators.Tag do
  @moduledoc """
  Helper to create tags
  """
  import NimbleParsec

  @doc """
  Define a tag from a tag_name and a function. The function `combinator` must expect
  a combinator and must returns a combinator

  The returned tag is a combinator which expect a start tag `{%` a tag name and a end tag `%}`

  The second parameter, function combinator, contains the specific behavior for defined tag

  ## Examples

      defmodule MyParser do
        import NimbleParsec
        alias Liquid.Combinators.Tag

        def ignorable, do: Tag.define(
          :ignorable,
          fn combinator -> combinator |> string("T") |> ignore() |> integer(2,2))

      MyParser.ignorable("{% ignorable T12 %}")
      #=> {:ok, {:ignorable, [12]}, "", %{}, {1, 0}, 2}
  """
  def define(tag_name, combinator \\ & &1) do
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string(Atom.to_string(tag_name))))
    |> combinator.()
    |> concat(parsec(:end_tag))
    |> tag(tag_name)
    |> optional(parsec(:__parse__))
  end
end
