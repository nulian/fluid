defmodule Liquid.Unless do
  @moduledoc """
  Conditional just like 'if' but works on the inverse logic.
  Input:
  ```
    {% unless x < 0 %} x is greater than zero {% endunless %}
  ```
  Output:
  ```
    x is greater than zero
  ```
  """
  alias Liquid.{Block, Condition, Context, IfElse, Render, Tag, Template}

  @doc """
  Implementation of 'Unless' parse operations
  """
  @spec parse(%Block{}, %Template{}) :: {%Block{}, %Template{}}
  def parse(%Block{} = block, %Template{} = t) do
    IfElse.parse(block, t)
  end

  @doc """
  Implementation of 'Unless' render operations
  """
  @spec render(list(), %Tag{}, %Context{}) :: {list(), %Context{}}
  def render(output, %Tag{}, context) do
    {output, context}
  end

  @spec render(list(), %Block{}, %Context{}) :: {list(), %Block{}, %Context{}}
  def render(
        output,
        %Block{condition: condition, nodelist: nodelist, elselist: elselist},
        context
      ) do
    condition = Condition.evaluate(condition, context)
    conditionlist = if condition, do: elselist, else: nodelist
    Render.render(output, conditionlist, context)
  end
end
