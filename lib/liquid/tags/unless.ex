defmodule Liquid.Unless do
  alias Liquid.IfElse
  alias Liquid.Block
  alias Liquid.Template
  alias Liquid.Condition
  alias Liquid.Tag
  alias Liquid.Render

  def parse(%Block{} = block, %Template{} = t, options) do
    IfElse.parse(block, t, options)
  end

  def render(output, %Tag{}, context, _options) do
    {output, context}
  end

  def render(
        output,
        %Block{condition: condition, nodelist: nodelist, elselist: elselist},
        context,
        options
      ) do
    condition = Condition.evaluate(condition, context, options)
    conditionlist = if condition, do: elselist, else: nodelist
    Render.render(output, conditionlist, context, options)
  end
end
