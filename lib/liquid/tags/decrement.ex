defmodule Liquid.Decrement do
  alias Liquid.Tag
  alias Liquid.Template
  alias Liquid.Context
  alias Liquid.Variable

  def parse(%Tag{} = tag, %Template{} = template) do
    {tag, template}
  end

  def render(output, %Tag{markup: markup}, %Context{} = context) do
    variable = Variable.create(markup)
    {rendered, context} = Variable.lookup(variable, context)
    value = rendered || 0
    result_assign = context.assigns |> Map.put(markup, value - 1)
    context = %{context | assigns: result_assign}
    {[value - 1] ++ output, context}
  end
end
