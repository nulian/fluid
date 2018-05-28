defmodule Liquid.Combinators.Tags.Increment do
  @moduledoc """
  Creates a new number variable, and increases its value by one every time it is called. The initial value is 0.
  Increment is used in a place where one needs to insert a counter into a template, and needs the counter to survive across
  multiple instantiations of the template.
  (To achieve the survival, the application must keep the context)
  if the variable does not exist, it is created with value 0.
  Input:
  ```
    Hello: {% increment variable %}
  ```
  Output:
  ```
    Hello: 0
    Hello: 1
    Hello: 2
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag do
    Tag.define_open("increment", fn combinator ->
      parsec(combinator, :variable_name)
    end)
  end
end
