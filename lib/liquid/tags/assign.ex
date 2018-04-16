defmodule Liquid.Assign do
  alias Liquid.Variable
  alias Liquid.Tag
  alias Liquid.Context

  def syntax, do: ~r/([\w\-]+)\s*=\s*(.*)\s*/

  def parse(%Tag{} = tag, %Liquid.Template{} = template), do: {%{tag | blank: true}, template}

  def render(output, %Tag{markup: markup}, %Context{} = context) do
    [[_, to, from]] = syntax() |> Regex.scan(markup)

    {from_value, context} =
      from
      |> Variable.create()
      |> Variable.lookup(context)

    result_assign = context.assigns |> Map.put(to, from_value)
    context = %{context | assigns: result_assign}
    {output, context}
  end
end
