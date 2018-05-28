defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Executes a block of code only if a certain condition is true.
  If this condition is false executes `else` block of code
  Input:
  ```
  {% if product.title == 'Awesome Shoes' %}
    These shoes are awesome!
  {% else %}
    These shoes are ugly!
  {% endif %}
  ```
  Output:
  ```
    These shoes are ugly!
  ```
  """

  import NimbleParsec
  alias Liquid.Combinators.Tag

  def elsif_tag, do: Tag.define_open("elsif", &predicate/1)

  def else_tag, do: Tag.define_open("else")

  def unless_tag, do: Tag.define_closed("unless", &predicate/1, &body/1)

  def tag, do: Tag.define_closed("if", &predicate/1, &body/1)

  defp body(combinator) do
    combinator
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(parsec(:else_tag), min: 1))
  end

  defp predicate(combinator) do
    combinator
    |> choice([
      parsec(:condition),
      parsec(:value_definition),
      parsec(:variable_definition)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
  end
end
