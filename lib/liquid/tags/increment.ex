defmodule Liquid.Increment do
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
  alias Liquid.Tag
  alias Liquid.Template
  alias Liquid.Context
  alias Liquid.Variable

  @doc """
  Implementation of 'Increment' parse operations
  """
  @spec parse(tag :: %Tag{}, template :: %Template{}) :: {%Tag{}, %Template{}}
  def parse(%Tag{} = tag, %Template{} = template) do
    {tag, template}
  end

  @doc """
  Implementation of 'Increment' render operations
  """
  @spec render(list(), %Tag{}, context :: %Context{}) :: {list(), %Context{}}
  def render(output, %Tag{markup: markup}, %Context{} = context) do
    variable = Variable.create(markup)
    {rendered, context} = Variable.lookup(variable, context)
    value = rendered || 0
    result_assign = context.assigns |> Map.put(markup, value + 1)
    context = %{context | assigns: result_assign}
    {[value] ++ output, context}
  end
end
