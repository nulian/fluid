defmodule Liquid.Combinators.Tags.Decrement do
  @moduledoc """
  Creates a new number variable, and decreases its value by one every time it is called.
  The initial value is -1.
  Decrement is used in a place where one needs to insert a counter into a template,
  and needs the counter to survive across
  multiple instantiations of the template.
  NOTE: decrement is a pre-decrement, -i, while increment is post: i+.
  (To achieve the survival, the application must keep the context)

  if the variable does not exist, it is created with value 0:
  Input:
  ```
    Hello: {% decrement variable %}
  ```
  Output:
  ```
    Hello: -1
    Hello: -2
    Hello: -3
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag do
    Tag.create_generic_tag(:decrement, fn combinator ->
      combinator
      |> concat(parsec(:variable_name))
    end)
  end
end
