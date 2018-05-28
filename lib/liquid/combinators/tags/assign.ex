defmodule Liquid.Combinators.Tags.Assign do
  @moduledoc """
  Sets variables in a template
  ```
    {% assign foo = 'monkey' %}
  ```
  User can then use the variables later in the page
  ```
    {{ foo }}
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag do
    Tag.define_open("assign", fn combinator ->
      combinator
      |> concat(parsec(:variable_name))
      |> concat(ignore(string("=")))
      |> concat(parsec(:value))
      |> optional(parsec(:filter))
    end)
  end
end
