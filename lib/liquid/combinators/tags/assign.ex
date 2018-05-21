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
    Tag.create_generic_tag(:assign, fn combinator ->
      combinator
      |> concat(parsec(:variable_name))
      |> concat(ignore(string("=")))
      |> concat(parsec(:value))
    end)
  end
end
