defmodule Liquid.Raw do
  alias Liquid.Render
  alias Liquid.Block

  def render(output, %Block{} = block, context) do
    Render.render(output, block.nodelist, context)
  end
end
