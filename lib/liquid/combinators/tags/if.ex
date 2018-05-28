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

  def elsif_tag, do: Tag.define("elsif", &predicate/1)

  def else_tag, do: Tag.define("else")

  def unless_tag, do: Tag.define("unless", &predicate/1, &body/1, "endunless")

  def tag, do: Tag.define("if", &predicate/1, &body/1, "endif")

  defp body(combinator) do
    combinator
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(parsec(:else_tag), min: 1))
  end

  defp predicate(combinator) do
    combinator
    |> choice([
      condition(),
      parsec(:variable_definition),
      parsec(:value_definition),
      parsec(:quoted_token)
    ])
    |> optional(times(logical_condition(), min: 1))
  end

  defp condition do
    empty()
    |> parsec(:value_definition)
    |> parsec(:comparison_operators)
    |> parsec(:value_definition)
    |> reduce({List, :to_tuple, []})
    |> unwrap_and_tag(:condition)
  end

  defp logical_condition do
    parsec(:logical_operators)
    |> choice([condition(), parsec(:variable_name), parsec(:value_definition)])
    |> tag(:logical)
  end
end
