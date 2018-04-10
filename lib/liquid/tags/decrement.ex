defmodule Liquid.Decrement do
  @moduledoc """
  Creates a new number variable, and decreases its value by one every time it is called. The initial value is -1.
  Decrement is used in a place where one needs to insert a counter into a template, and needs the counter to survive across
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
  alias Liquid.Tag
  alias Liquid.Template
  alias Liquid.Context
  alias Liquid.Variable

  @doc """
  Identity function. Implementation of Decrement parse operations
  """
  @spec parse(tag :: %Tag{}, template :: %Template{}) :: {%Tag{}, %Template{}}
  def parse(%Tag{} = tag, %Template{} = template) do
    {tag, template}
  end

  @doc """
  Implementation of Decrement render operations
  """
  @spec render(list(), %Tag{}, %Context{}) :: {list(), %Context{}}
  def render(output, %Tag{markup: markup}, %Context{} = context) do
    variable = Variable.create(markup)
    {rendered, context} = Variable.lookup(variable, context)
    value = rendered || 0
    result_assign = context.assigns |> Map.put(markup, value - 1)
    context = %{context | assigns: result_assign}
    {[value - 1] ++ output, context}
  end
end
