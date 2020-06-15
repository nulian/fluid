defmodule Liquid.Assign do
  alias Liquid.Variable
  alias Liquid.Tag
  alias Liquid.Context

  @compile {:inline, syntax: 0}
  def syntax, do: ~r/([\w\-]+)\s*=\s*(.*)\s*/

  def parse(%Tag{} = tag, %Liquid.Template{} = template, _options),
    do: {%{tag | blank: true}, template}

  def render(output, %Tag{markup: markup}, %Context{} = context, options) do
    [[_, to, from]] = syntax() |> Regex.scan(markup)

    {from_value, context} =
      from
      |> Variable.create()
      |> Variable.lookup(context, options)

    result_assign = context.assigns |> Map.put(to, from_value)
    context = %{context | assigns: result_assign}
    {output, context}
  end
end
