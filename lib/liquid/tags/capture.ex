defmodule Liquid.Capture do
  alias Liquid.Block
  alias Liquid.Context
  alias Liquid.Template

  def parse(%Block{} = block, %Template{} = template, _options) do
    {%{block | blank: true}, template}
  end

  def render(output, %Block{markup: markup, nodelist: content}, %Context{} = context, options) do
    variable_name = Liquid.Parse.variable_parser() |> Regex.run(markup) |> hd
    {block_output, context} = Liquid.Render.render([], content, context, options)

    result_assign =
      context.assigns |> Map.put(variable_name, block_output |> Liquid.Render.to_text())

    context = %{context | assigns: result_assign}
    {output, context}
  end
end
