defmodule Liquid.Unless do
  alias Liquid.IfElse
  alias Liquid.Block
  alias Liquid.Template
  alias Liquid.Condition
  alias Liquid.Tag
  alias Liquid.Render

  def parse(%Block{} = block, %Template{} = t) do
    IfElse.parse(block, t)
  end

  def render(output, %Tag{}, context) do
    {output, context}
  end

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
