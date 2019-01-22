defmodule Liquid.Unless do
  alias Liquid.Block
  alias Liquid.Condition
  alias Liquid.Tag
  alias Liquid.Render

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
