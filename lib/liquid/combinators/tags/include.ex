defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include enables the possibility to include and render other liquid templates.
  Templates can also be recursively included.
  """
  import NimbleParsec
  alias Liquid.Combinators.{Tag, General, LexicalToken}

  @type t :: [include: Include.markup()]

  @type markup :: [
          variable_name: String.t(),
          params: [assignment: [variable_name: String.t(), value: LexicalToken.value()]]
        ]

  @doc """
  Parses a `Liquid` Include tag, creates a Keyword list where the key is the name of the tag
  (include in this case) and the value is another keyword list which represents the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag, do: Tag.define_open("include", &head/1)

  def tag2, do: head(empty())

  defp params do
    General.codepoints().colon
    |> General.assignment()
    |> tag(:assignment)
    |> times(min: 1)
    |> tag(:params)
  end

  defp predicate(name) do
    empty()
    |> ignore(string(name))
    |> concat(LexicalToken.value_definition())
    |> tag(String.to_atom(name))
  end

  defp head(combinator) do
    combinator
    |> concat(General.quoted_variable_name())
    |> optional(choice([predicate("with"), predicate("for"), params()]))
  end
end
