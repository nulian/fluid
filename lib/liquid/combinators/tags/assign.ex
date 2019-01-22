defmodule Liquid.Combinators.Tags.Assign do
  @moduledoc """
  Sets variables in a template.
  ```
    {% assign foo = 'monkey' %}
  ```
  User can then use the variables later in the page.
  ```
    {{ foo }}
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag, LexicalToken}

  @type t :: [assign: Assign.markup()]

  @type markup :: [variable_name: String.t(), value: LexicalToken.value()]

  @doc """
  Parses a `Liquid` Assign tag, creates a Keyword list where the key is the name of the tag
  (assign in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    Tag.define_open("assign", fn combinator ->
      combinator
      |> concat(General.assignment(General.codepoints().equal))
      |> optional(General.filters())
    end)
  end
end
